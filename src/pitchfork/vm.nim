# Pitchfork VM Executor: Bytecode + Data -> Text
# ==============================================
# Takes compiled bytecode and runtime data, produces output.
# Language-agnostic: template-language specifics are provided through
# tag_handlers, the filter registry, and partial_compiler.

import std/[tables, strutils, sequtils, algorithm, sets]
import bytecode
import vm_types
import values
import filters

export vm_types

when defined(opcode_coverage):
  import std/exitprocs
  var opcode_seen: set[OpCode]
  addExitProc(proc() =
    var missed: seq[string] = @[]
    for op in OpCode:
      if op notin opcode_seen: missed.add($op)
    echo "OPCOV executed=", card(opcode_seen), "/", ord(high(OpCode)) + 1,
         " missed=", missed.join(","))

# Create VM with data
proc new_vm*(bytecode: seq[Instruction], strings: seq[string],
             constants: seq[VMValue], data: Table[string, VMValue],
             partials: Table[string, string] = initTable[string, string]()): VM =
  # Remaining fields rely on Nim's usable zero values (empty tables/seqs)
  # to keep per-render VM construction cheap.
  result = VM(
    stack: newSeqOfCap[VMValue](32),
    bytecode: bytecode,
    strings: strings,
    constants: constants,
    variables: data,
    partials: partials,
  )

# Stack operations
template push*(vm: var VM, val: VMValue) =
  vm.stack.add(val)
  vm.max_stack_size = max(vm.max_stack_size, vm.stack.len)

template pop*(vm: var VM): VMValue =
  if vm.stack.len > 0:
    vm.stack.pop()
  else:
    VMValue(kind: vmNull)

template peek*(vm: VM, offset: int = 0): VMValue =
  if vm.stack.len > offset:
    vm.stack[vm.stack.len - 1 - offset]
  else:
    VMValue(kind: vmNull)

# ─── Path tracking (shadow stack for dependency tracking) ────────────

template push_path(vm: var VM, path: string) =
  if vm.track_access:
    vm.path_stack.add(path)

template pop_path(vm: var VM): string =
  if vm.track_access and vm.path_stack.len > 0:
    vm.path_stack.pop()
  else:
    ""

template record_path(vm: var VM, path: string) =
  if vm.track_access and path.len > 0:
    vm.accessed_paths.incl(path)

template pop_and_record(vm: var VM) =
  if vm.track_access:
    let p = vm.pop_path()
    if p.len > 0:
      vm.accessed_paths.incl(p)

# Pop two paths, record both, push empty (for binary ops producing computed values)
template pop2_record_push0(vm: var VM) =
  if vm.track_access:
    let pb = vm.pop_path()
    let pa = vm.pop_path()
    if pa.len > 0: vm.accessed_paths.incl(pa)
    if pb.len > 0: vm.accessed_paths.incl(pb)
    vm.path_stack.add("")

# Value operations
proc is_truthy(v: VMValue): bool =
  ## In Liquid, only nil and false are falsy. Everything else is truthy,
  ## including 0, 0.0, "", [], {}.
  case v.kind
  of vmNull: false
  of vmBool: v.boolVal
  else: true

proc is_empty(v: VMValue): bool =
  case v.kind
  of vmNull: true
  of vmString: v.stringVal.len == 0
  of vmArray: v.arrayVal.len == 0
  of vmObject: v.objectVal.len == 0
  else: false

proc liquid_eq(a, b: VMValue): bool =
  ## Liquid equality with cross-type numeric comparison and empty support
  if a.kind == vmEmpty:
    return b.is_empty()
  if b.kind == vmEmpty:
    return a.is_empty()
  if a.kind == b.kind:
    return a == b
  # Cross-type int/float comparison
  if a.kind == vmInt and b.kind == vmFloat:
    return a.intVal.float64 == b.floatVal
  if a.kind == vmFloat and b.kind == vmInt:
    return a.floatVal == b.intVal.float64
  return false

proc liquid_compare(a, b: VMValue): int =
  ## Compare two VMValues. Returns -1, 0, or 1.
  ## Raises ValueError for incompatible types.
  if a.kind == vmInt and b.kind == vmInt:
    return cmp(a.intVal, b.intVal)
  if a.kind == vmFloat and b.kind == vmFloat:
    return cmp(a.floatVal, b.floatVal)
  if a.kind == vmInt and b.kind == vmFloat:
    return cmp(a.intVal.float64, b.floatVal)
  if a.kind == vmFloat and b.kind == vmInt:
    return cmp(a.floatVal, b.intVal.float64)
  if a.kind == vmString and b.kind == vmString:
    return cmp(a.stringVal, b.stringVal)
  raise newException(ValueError,
    "comparison of incompatible types: " & $a.kind & " <=> " & $b.kind)

proc escape_html_str(s: string): string =
  result = newStringOfCap(s.len + 10)
  for c in s:
    case c
    of '&': result.add("&amp;")
    of '<': result.add("&lt;")
    of '>': result.add("&gt;")
    of '"': result.add("&quot;")
    of '\'': result.add("&#39;")
    else: result.add(c)

# ─── VM Helpers ───────────────────────────────────────────────────────

template emit_output*(vm: var VM, str: string) =
  ## Emit text to current output target (capture stack or main output)
  if vm.is_capturing:
    vm.capture_stack[^1].add(str)
  else:
    vm.output.add(str)

proc resolve_var*(vm: var VM, name: string): VMValue =
  ## Resolve a variable name through the scope chain:
  ## keyword_args → locals → variables → counters → null
  ##
  ## One probe per scope level: `in` followed by `[]` hashed the name and
  ## walked each table twice. Order is preserved — presence decides, so a
  ## level holding an explicit null still shadows the levels below it.
  vm.keyword_args.withValue(name, found):
    return found[]
  vm.locals.withValue(name, found):
    return found[]
  vm.variables.withValue(name, found):
    return found[]
  vm.counters.withValue(name, found):
    return VMValue(kind: vmInt, intVal: found[])
  VMValue(kind: vmNull)

proc to_int64*(v: VMValue, strict: bool = true): int64 =
  ## Convert a VMValue to int64.
  ## In strict mode (default), raises on incompatible types.
  ## In lenient mode, returns 0 for incompatible types.
  case v.kind
  of vmInt: v.intVal
  of vmFloat: v.floatVal.int64
  of vmString:
    try: parseInt(v.stringVal).int64
    except ValueError:
      if strict:
        raise newException(ValueError, "expected a number, got string '" & v.stringVal & "'")
      else: 0'i64
  of vmNull: 0'i64
  else:
    if strict:
      raise newException(ValueError, "expected a number, got " & $v.kind)
    else: 0'i64

proc build_forloop*(idx0, length: int, name: string, parent: VMValue,
                    key: VMValue = vm_null()): VMValue =
  ## Build a forloop helper object for loops ({% for %}, Mustache sections,
  ## Handlebars #each). key carries the object key when iterating an object
  ## as values (Handlebars @key).
  var obj = {
    "index": vm_int((idx0 + 1).int64),
    "index0": vm_int(idx0.int64),
    "first": vm_bool(idx0 == 0),
    "last": vm_bool(idx0 == length - 1),
    "length": vm_int(length.int64),
    "rindex": vm_int((length - idx0).int64),
    "rindex0": vm_int((length - idx0 - 1).int64),
    "name": vm_string(name),
  }.toTable
  if key.kind != vm_null:
    obj["key"] = key
  if parent.kind != vm_null:
    obj["parentloop"] = parent
  else:
    obj["parentloop"] = vm_null()
  vm_object(obj)

proc finish_iterator*(vm: var VM, iter_index: int = -1) =
  ## Clean up a finished iterator: save offset, remove from stack,
  ## restore parent forloop, delete loop variable from locals
  let idx = if iter_index < 0: vm.iterators.len - 1 else: iter_index
  let finished = vm.iterators[idx]
  vm.loop_offsets[finished.var_name] = finished.original_offset + finished.items.len
  vm.iterators.delete(idx)
  vm.locals.del(finished.var_name)
  if finished.saved_forloop.kind != vm_null:
    vm.locals["forloop"] = finished.saved_forloop
  else:
    vm.locals.del("forloop")

proc indent_lines(s, indent: string): string =
  ## Prepend indent to every line of s (Mustache standalone-partial
  ## indentation, applied to the partial's source before compilation so
  ## multi-line interpolated values stay unindented, per spec).
  ## A trailing newline does not produce a dangling indent.
  if indent.len == 0 or s.len == 0:
    return s
  result = newStringOfCap(s.len + indent.len * 4)
  var at_line_start = true
  for ch in s:
    if at_line_start:
      result.add(indent)
      at_line_start = false
    result.add(ch)
    if ch == '\n':
      at_line_start = true

# ─── Partial Execution Helpers ───────────────────────────────────────

proc compile_partial*(vm: var VM, name: string, indent: string = ""):
    tuple[bytecode: seq[Instruction], strings: seq[string],
          constants: seq[VMValue], found: bool] =
  ## Look up partial source, compile on first use, cache result.
  ## Compilation goes through vm.partial_compiler so partials are compiled
  ## in the same template language as the including template.
  ## A non-empty indent (Mustache standalone partials) is applied to the
  ## partial's source lines before compilation, and is part of the cache key.
  ## Returns found=false if partial doesn't exist.
  if name notin vm.partials:
    result.found = false
    return
  let cache_key = name & '\31' & indent
  if cache_key notin vm.partial_cache:
    if vm.partial_compiler == nil:
      raise newException(CatchableError,
        "Cannot compile partial '" & name & "': no partial_compiler set on VM")
    let compiled = vm.partial_compiler(indent_lines(vm.partials[name], indent))
    vm.partial_cache[cache_key] = (compiled.bytecode, compiled.strings, compiled.constants)
  let cached = vm.partial_cache[cache_key]
  result = (cached.bytecode, cached.strings, cached.constants, true)

proc create_sub_vm*(vm: var VM, bytecode: seq[Instruction],
                    strings: seq[string], constants: seq[VMValue],
                    shared_scope: bool): VM =
  ## Create a sub-VM for partial execution.
  ## shared_scope=true (include): shares variables, locals, loop_offsets, counters
  ## shared_scope=false (render): isolated empty scope
  result = new_vm(bytecode, strings, constants,
    if shared_scope: vm.variables else: initTable[string, VMValue](),
    vm.partials)
  if shared_scope:
    result.locals = vm.locals
    result.loop_offsets = vm.loop_offsets
    result.counters = vm.counters
    result.ctx_stack = vm.ctx_stack
  result.partial_cache = vm.partial_cache
  result.partial_compiler = vm.partial_compiler
  result.tag_handlers = vm.tag_handlers
  result.track_access = vm.track_access

proc propagate_scope*(vm: var VM, sub: VM,
                      shared_scope: bool, propagate_control: bool = true) =
  ## Propagate state from sub-VM back to parent.
  ## Only propagates for include (shared_scope=true).
  ## propagate_control=true also copies counters and break/continue flags.
  vm.partial_cache = sub.partial_cache
  if shared_scope:
    vm.locals = sub.locals
    vm.loop_offsets = sub.loop_offsets
    if propagate_control:
      vm.counters = sub.counters
      if sub.pending_break: vm.pending_break = true
      if sub.pending_continue: vm.pending_continue = true
  # Merge accessed paths from sub-VM (transitive tracking)
  if vm.track_access:
    for path in sub.accessed_paths:
      vm.accessed_paths.incl(path)

proc bind_keyword_args*(sub: var VM,
                        kwArgs: seq[(string, VMValue)],
                        shared_scope: bool) =
  ## Bind keyword arguments to sub-VM.
  ## shared_scope=true: keyword_args overlay (read-only)
  ## shared_scope=false: locals (isolated)
  if shared_scope:
    for (k, v) in kwArgs:
      sub.keyword_args[k] = v
  else:
    for (k, v) in kwArgs:
      sub.locals[k] = v


# Main execution function
proc execute*(vm: var VM): string =
  ## Execute the bytecode and return the output
  
  while vm.pc < vm.bytecode.len:
    let inst {.cursor.} = vm.bytecode[vm.pc]
    inc vm.pc
    inc vm.instruction_count
    when defined(opcode_coverage):
      opcode_seen.incl(inst.op)

    # When pending break/continue is active, skip all instructions except
    # opIterNext (which handles the break/continue) and opStoreVar (to pop stack)
    if (vm.pending_break or vm.pending_continue) and inst.op != opIterNext:
      # Skip instructions, but pop any stack values that were pushed
      case inst.op
      of opStoreVar:
        discard vm.pop()
        vm.pop_and_record()
      else:
        discard
      continue

    case inst.op
    # Stack operations
    of opPushNull:
      vm.push(VMValue(kind: vmNull))
      vm.push_path("")

    of opPushEmpty:
      vm.push(VMValue(kind: vmEmpty))
      vm.push_path("")

    of opPushTrue:
      vm.push(VMValue(kind: vmBool, boolVal: true))
      vm.push_path("")

    of opPushFalse:
      vm.push(VMValue(kind: vmBool, boolVal: false))
      vm.push_path("")

    of opPushInt:
      vm.push(VMValue(kind: vmInt, intVal: inst.intVal))
      vm.push_path("")

    of opPushFloat:
      vm.push(VMValue(kind: vmFloat, floatVal: inst.floatVal))
      vm.push_path("")

    of opPushString:
      vm.push(VMValue(kind: vmString, stringVal: vm.strings[inst.stringId]))
      vm.push_path("")

    of opPop:
      discard vm.pop()
      discard vm.pop_path()

    of opDup:
      if vm.stack.len > 0:
        vm.push(vm.peek())
        if vm.track_access and vm.path_stack.len > 0:
          vm.path_stack.add(vm.path_stack[^1])
    
    # Variable operations
    of opResolveName:
      # Scoped resolution: walk the context stack top-down for an object
      # frame containing the name, then fall back to the flat scope chain
      # (keyword_args → locals → variables → counters). With an empty
      # context stack (Liquid) this is a plain variable load.
      let name = vm.strings[inst.nameId]
      # ctxHops skips frames from the top (Handlebars ../ — one hop per
      # enclosing block that pushed a context frame)
      let top = vm.ctx_stack.len - 1 - inst.ctxHops.int
      var found_in_ctx = false
      var found_frame = -1
      if top >= 0:
        if name == ".":
          # Implicit iterator / `this`: the current context itself
          vm.push(vm.ctx_stack[top])
          found_in_ctx = true
        elif name == "@root":
          vm.push(vm.ctx_stack[0])
          found_in_ctx = true
        else:
          for i in countdown(top, 0):
            let frame = vm.ctx_stack[i]
            if frame.kind == vmObject and name in frame.objectVal:
              vm.push(frame.objectVal[name])
              found_in_ctx = true
              found_frame = i
              break
      if not found_in_ctx:
        if inst.ctxHops > 0:
          # A parent path that walked past the root resolves to nothing
          vm.push(VMValue(kind: vmNull))
        else:
          vm.push(vm.resolve_var(name))
      if vm.track_access:
        # Direct context variables get a path: the flat variables table
        # (Liquid) or the root context frame (Mustache). Inner frames,
        # locals and counters don't — their absolute path is unknowable.
        if found_in_ctx:
          if found_frame == 0:
            vm.push_path(name)
          else:
            vm.push_path("")
        elif inst.ctxHops == 0 and name in vm.variables:
          vm.push_path(name)
        else:
          vm.push_path("")

    of opPushCtx:
      vm.ctx_stack.add(vm.pop())
      vm.pop_and_record()

    of opPopCtx:
      if vm.ctx_stack.len > 0:
        discard vm.ctx_stack.pop()

    of opSetCtx:
      let val = vm.pop()
      vm.pop_and_record()
      if vm.ctx_stack.len > 0:
        vm.ctx_stack[^1] = val

    of opDynamicLoadVar:
      # Pop key from stack, use it as a variable name
      let name = vm.pop().to_string()
      discard vm.pop_path()  # Pop path for the key value
      vm.push(vm.resolve_var(name))
      if vm.track_access:
        if name in vm.variables:
          vm.push_path(name)
        else:
          vm.push_path("")

    of opStoreVar:
      let var_name = vm.strings[inst.stringId]
      let value = vm.pop()
      vm.pop_and_record()  # Value consumed into local — still record the dependency
      vm.locals[var_name] = value

    # Property access
    of opGetProp:
      let obj = vm.pop()
      let parent_path = vm.pop_path()
      let prop_name = vm.strings[inst.stringId]

      case obj.kind
      of vmObject:
        # Check for actual property first
        if prop_name in obj.objectVal:
          vm.push(obj.objectVal[prop_name])
        else:
          # Fall back to special/virtual properties
          case prop_name
          of "size", "length":
            vm.push(VMValue(kind: vmInt, intVal: obj.objectVal.len.int64))
          of "first":
            # Return first key-value pair as [key, value] array
            if obj.objectVal.len > 0:
              for k, v in obj.objectVal:
                vm.push(VMValue(kind: vmArray, arrayVal: @[
                  VMValue(kind: vmString, stringVal: k), v]))
                break
            else:
              vm.push(VMValue(kind: vmNull))
          else:
            vm.push(VMValue(kind: vmNull))
      of vmArray:
        # Numeric property: index access (Handlebars a.[0], Mustache-family
        # dotted numeric segments)
        if prop_name.len > 0 and prop_name.allCharsInSet({'0'..'9'}):
          let idx = try: parseInt(prop_name) except ValueError: -1
          if idx >= 0 and idx < obj.arrayVal.len:
            vm.push(obj.arrayVal[idx])
          else:
            vm.push(VMValue(kind: vmNull))
          if vm.track_access:
            if parent_path.len > 0:
              vm.push_path(parent_path & "[" & prop_name & "]")
            else:
              vm.push_path("")
          continue
        # Special array properties
        case prop_name
        of "size", "length":
          vm.push(VMValue(kind: vmInt, intVal: obj.arrayVal.len.int64))
        of "first":
          if obj.arrayVal.len > 0:
            vm.push(obj.arrayVal[0])
          else:
            vm.push(VMValue(kind: vmNull))
        of "last":
          if obj.arrayVal.len > 0:
            vm.push(obj.arrayVal[^1])
          else:
            vm.push(VMValue(kind: vmNull))
        else:
          vm.push(VMValue(kind: vmNull))
      of vmString:
        # Special string properties
        case prop_name
        of "size", "length":
          vm.push(VMValue(kind: vmInt, intVal: obj.stringVal.len.int64))
        else:
          vm.push(VMValue(kind: vmNull))
      else:
        vm.push(VMValue(kind: vmNull))
      # Extend path chain: user → user.name
      if vm.track_access:
        if parent_path.len > 0:
          vm.push_path(parent_path & "." & prop_name)
        else:
          vm.push_path("")

    # Output operations
    of opOutput:
      # Values render straight into the target buffer. Going through
      # to_string first copied the value's text once to build the string
      # and again to append it; an integer allocated a string just to be
      # thrown away. Only escaping still needs an intermediate, and it is
      # off by default.
      let val = vm.pop()
      vm.pop_and_record()

      if vm.is_capturing:
        # When capturing, store raw (escaping happens on final output)
        vm.capture_stack[^1].add_to_string(val)
      elif vm.escape_html:
        vm.output.add(val.to_string().escape_html_str())
      else:
        vm.output.add_to_string(val)

    of opOutputEscaped:
      # Always HTML-escape, regardless of the vm.escape_html default
      # (Mustache {{ }}; Liquid uses opOutput + the VM-level flag)
      let val = vm.pop()
      vm.pop_and_record()
      vm.emit_output(val.to_string().escape_html_str())

    of opBatchOutput:
      # Batch output is ALWAYS literal template text - NEVER escape
      vm.emit_output(vm.strings[inst.stringId])
    
    of opBeginCapture:
      # Start capturing output
      vm.capture_stack.add("")
      vm.is_capturing = true
      # Save current escape state and disable escaping during capture
      vm.capture_escape_stack.add(vm.escape_html)
      vm.escape_html = false
    
    of opEndCapture:
      if vm.capture_stack.len > 0:
        let captured_output = vm.capture_stack.pop()
        let var_name = vm.strings[inst.varId]
        # Store captured content as-is (already unescaped)
        vm.locals[var_name] = VMValue(kind: vmString, stringVal: captured_output)
        vm.is_capturing = vm.capture_stack.len > 0
        # Restore escape state from before this capture
        if vm.capture_escape_stack.len > 0:
          vm.escape_html = vm.capture_escape_stack.pop()
    
    of opCallTag:
      # Runtime dispatch to registered tag handler. One probe of the
      # registry, not two — and the name is read out of the string pool
      # only on the error path.
      var handler: TagRuntimeHandler = nil
      vm.tag_handlers.withValue(vm.strings[inst.tagId], found):
        handler = found[]
      if handler.isNil:
        raise newException(CatchableError,
          "Unknown tag handler: " & vm.strings[inst.tagId])
      handler(vm, inst)

    of opBeginBlankCheck:
      # Record current output position for blank detection
      if vm.is_capturing:
        vm.blank_check_stack.add(vm.capture_stack[^1].len)
      else:
        vm.blank_check_stack.add(vm.output.len)

    of opEndBlankCheck:
      # Check if output since begin is whitespace-only
      if vm.blank_check_stack.len > 0:
        let startPos = vm.blank_check_stack.pop()
        if vm.is_capturing:
          let output = vm.capture_stack[^1]
          var isBlank = true
          for i in startPos..<output.len:
            if output[i] notin {' ', '\t', '\n', '\r'}:
              isBlank = false
              break
          if isBlank:
            vm.capture_stack[^1].setLen(startPos)
        else:
          var isBlank = true
          for i in startPos..<vm.output.len:
            if vm.output[i] notin {' ', '\t', '\n', '\r'}:
              isBlank = false
              break
          if isBlank:
            vm.output.setLen(startPos)

    # Control flow
    of opJump:
      vm.pc += inst.offset
      
    of opJumpIfFalse:
      let cond = vm.pop()
      vm.pop_and_record()
      if not cond.is_truthy():
        vm.pc += inst.offset

    of opJumpIfTrue:
      let cond = vm.pop()
      vm.pop_and_record()
      if cond.is_truthy():
        vm.pc += inst.offset
    
    # Loops
    of opBeginLoop:
      # Pop limit and offset values if present (limit is on top, then offset, then collection)
      var limit_val = -1'i64  # -1 means no limit
      var offset_val = 0'i64  # 0 means no offset

      if inst.hasLimit:
        limit_val = vm.pop().to_int64()
        vm.pop_and_record()

      if inst.hasOffset:
        offset_val = vm.pop().to_int64()
        vm.pop_and_record()

      # Get loop variable name for offset: continue tracking
      let loop_var_name = vm.strings[inst.loopVarIndex]

      # Clean up any stale iterator for this variable (from a broken loop)
      for i in countdown(vm.iterators.len - 1, 0):
        if vm.iterators[i].var_name == loop_var_name:
          vm.finish_iterator(i)
          break

      # Handle offset: continue (resume from where last loop left off)
      if inst.hasOffsetContinue:
        if loop_var_name in vm.loop_offsets:
          offset_val = vm.loop_offsets[loop_var_name].int64

      let collection = vm.pop()
      vm.pop_and_record()  # Collection consumed — record dependency
      var items: seq[VMValue] = @[]

      var obj_keys: seq[string] = @[]
      case collection.kind
      of vmArray:
        items = collection.arrayVal
      of vmObject:
        if inst.objectAsValues:
          # Iterate values, tracking keys (Handlebars #each: @key)
          for key, val in collection.objectVal:
            obj_keys.add(key)
            items.add(val)
        else:
          # Convert object to array of key-value pairs (Liquid)
          for key, val in collection.objectVal:
            items.add(VMValue(kind: vmArray, arrayVal: @[
              VMValue(kind: vmString, stringVal: key),
              val
            ]))
      of vmString:
        # Iterate string as single item
        if collection.stringVal.len > 0:
          items = @[collection]
      else:
        discard  # Empty items for non-iterable

      let total_items = items.len

      # Apply offset
      if offset_val > 0 and offset_val < items.len.int64:
        items = items[offset_val..^1]
      elif offset_val >= items.len.int64:
        items = @[]

      # Apply limit
      if limit_val >= 0 and limit_val < items.len.int64:
        items = items[0..<limit_val]

      # Apply reversed
      if inst.isReversed:
        items.reverse()

      # Save current forloop value in the iterator for nesting restore
      let saved_fl = if "forloop" in vm.locals: vm.locals["forloop"] else: vm_null()

      # Get loop name from instruction
      let loop_name = if inst.loopNameId >= 0: vm.strings[inst.loopNameId] else: ""

      vm.iterators.add(Iterator(
        items: items,
        keys: obj_keys,
        builds_forloop: inst.buildsForloop,
        index: 0,
        var_name: loop_var_name,
        original_offset: offset_val.int,
        saved_forloop: saved_fl,
        loop_name: loop_name
      ))

    of opIterNext:
      if vm.iterators.len > 0:
        if vm.pending_break:
          # Break from included partial: end the loop immediately
          vm.pending_break = false
          vm.finish_iterator()
          vm.pc += inst.endOffset
        elif vm.pending_continue:
          # Continue from included partial: skip to next iteration
          vm.pending_continue = false
          var iter = addr vm.iterators[^1]
          if iter.index < iter.items.len:
            vm.push(iter.items[iter.index])
            vm.push_path("")  # Loop items are derived, not direct context
            iter.index += 1
            if iter.builds_forloop:
              let idx0 = iter.index - 1
              let key = if idx0 < iter.keys.len: vm_string(iter.keys[idx0]) else: vm_null()
              vm.locals["forloop"] = build_forloop(idx0, iter.items.len, iter.loop_name, iter.saved_forloop, key)
          else:
            vm.finish_iterator()
            vm.pc += inst.endOffset
        else:
          # Normal iteration
          var iter = addr vm.iterators[^1]
          if iter.index < iter.items.len:
            vm.push(iter.items[iter.index])
            vm.push_path("")  # Loop items are derived, not direct context
            iter.index += 1
            if iter.builds_forloop:
              let idx0 = iter.index - 1
              let key = if idx0 < iter.keys.len: vm_string(iter.keys[idx0]) else: vm_null()
              vm.locals["forloop"] = build_forloop(idx0, iter.items.len, iter.loop_name, iter.saved_forloop, key)
          else:
            let wasEmpty = iter.index == 0
            vm.finish_iterator()
            if wasEmpty and inst.elseOffset != 0:
              vm.pc += inst.elseOffset
            else:
              vm.pc += inst.endOffset
    
    # Comparison
    of opEqual:
      let b = vm.pop()
      let a = vm.pop()
      vm.pop2_record_push0()
      vm.push(VMValue(kind: vmBool, boolVal: liquid_eq(a, b)))

    of opNotEqual:
      let b = vm.pop()
      let a = vm.pop()
      vm.pop2_record_push0()
      vm.push(VMValue(kind: vmBool, boolVal: not liquid_eq(a, b)))

    of opLess:
      let b = vm.pop()
      let a = vm.pop()
      vm.pop2_record_push0()
      vm.push(VMValue(kind: vmBool, boolVal: liquid_compare(a, b) < 0))

    of opLessEqual:
      let b = vm.pop()
      let a = vm.pop()
      vm.pop2_record_push0()
      vm.push(VMValue(kind: vmBool, boolVal: liquid_compare(a, b) <= 0))

    of opGreater:
      let b = vm.pop()
      let a = vm.pop()
      vm.pop2_record_push0()
      vm.push(VMValue(kind: vmBool, boolVal: liquid_compare(a, b) > 0))

    of opGreaterEqual:
      let b = vm.pop()
      let a = vm.pop()
      vm.pop2_record_push0()
      vm.push(VMValue(kind: vmBool, boolVal: liquid_compare(a, b) >= 0))
    
    of opContains:
      let needle = vm.pop()  # What we're looking for
      let haystack = vm.pop()  # Where we're looking
      vm.pop2_record_push0()

      case haystack.kind
      of vmString:
        # String contains substring
        if needle.kind == vmString:
          vm.push(VMValue(kind: vmBool, boolVal: needle.stringVal in haystack.stringVal))
        else:
          # Convert needle to string for string search
          vm.push(VMValue(kind: vmBool, boolVal: needle.to_string() in haystack.stringVal))
      of vmArray:
        # Array contains element
        var found = false
        for item in haystack.arrayVal:
          if item == needle:
            found = true
            break
        vm.push(VMValue(kind: vmBool, boolVal: found))
      else:
        # Other types don't support contains
        vm.push(VMValue(kind: vmBool, boolVal: false))
    
    of opDivide:
      let b = vm.pop()
      let a = vm.pop()
      vm.pop2_record_push0()

      # Handle division by zero gracefully
      if a.kind == vmInt and b.kind == vmInt:
        if b.intVal == 0:
          # Division by zero - push 0 or NaN
          vm.push(VMValue(kind: vmNull))
        else:
          vm.push(VMValue(kind: vmInt, intVal: a.intVal div b.intVal))
      elif a.kind in [vmInt, vmFloat] and b.kind in [vmInt, vmFloat]:
        let af = if a.kind == vmInt: a.intVal.float else: a.floatVal
        let bf = if b.kind == vmInt: b.intVal.float else: b.floatVal
        if bf == 0.0:
          # Float division by zero gives Infinity
          vm.push(VMValue(kind: vmFloat, floatVal: Inf))
        else:
          vm.push(VMValue(kind: vmFloat, floatVal: af / bf))
      else:
        vm.push(VMValue(kind: vmNull))

    of opModulo:
      let b = vm.pop()
      let a = vm.pop()
      vm.pop2_record_push0()

      if a.kind == vmInt and b.kind == vmInt:
        if b.intVal == 0:
          # Modulo by zero - push 0 or null
          vm.push(VMValue(kind: vmNull))
        else:
          vm.push(VMValue(kind: vmInt, intVal: a.intVal mod b.intVal))
      else:
        vm.push(VMValue(kind: vmNull))

    of opAdd:
      let b = vm.pop()
      let a = vm.pop()
      vm.pop2_record_push0()

      # Handle different type combinations (null treated as 0 for arithmetic)
      if a.kind == vmInt and b.kind == vmInt:
        vm.push(VMValue(kind: vmInt, intVal: a.intVal + b.intVal))
      elif a.kind == vmNull and b.kind == vmInt:
        vm.push(VMValue(kind: vmInt, intVal: b.intVal))
      elif a.kind == vmInt and b.kind == vmNull:
        vm.push(VMValue(kind: vmInt, intVal: a.intVal))
      elif a.kind == vmString or b.kind == vmString:
        # String concatenation
        let aStr = a.to_string()
        let bStr = b.to_string()
        vm.push(VMValue(kind: vmString, stringVal: aStr & bStr))
      elif a.kind in [vmInt, vmFloat, vmNull] and b.kind in [vmInt, vmFloat, vmNull]:
        let af = case a.kind
          of vmInt: a.intVal.float
          of vmFloat: a.floatVal
          else: 0.0
        let bf = case b.kind
          of vmInt: b.intVal.float
          of vmFloat: b.floatVal
          else: 0.0
        vm.push(VMValue(kind: vmFloat, floatVal: af + bf))
      else:
        vm.push(VMValue(kind: vmNull))

    of opSubtract:
      let b = vm.pop()
      let a = vm.pop()
      vm.pop2_record_push0()

      # Handle different type combinations (null treated as 0 for arithmetic)
      if a.kind == vmInt and b.kind == vmInt:
        vm.push(VMValue(kind: vmInt, intVal: a.intVal - b.intVal))
      elif a.kind == vmNull and b.kind == vmInt:
        vm.push(VMValue(kind: vmInt, intVal: -b.intVal))
      elif a.kind == vmInt and b.kind == vmNull:
        vm.push(VMValue(kind: vmInt, intVal: a.intVal))
      elif a.kind in [vmInt, vmFloat, vmNull] and b.kind in [vmInt, vmFloat, vmNull]:
        let af = case a.kind
          of vmInt: a.intVal.float
          of vmFloat: a.floatVal
          else: 0.0
        let bf = case b.kind
          of vmInt: b.intVal.float
          of vmFloat: b.floatVal
          else: 0.0
        vm.push(VMValue(kind: vmFloat, floatVal: af - bf))
      else:
        vm.push(VMValue(kind: vmNull))

    of opMultiply:
      let b = vm.pop()
      let a = vm.pop()
      vm.pop2_record_push0()

      if a.kind == vmInt and b.kind == vmInt:
        vm.push(VMValue(kind: vmInt, intVal: a.intVal * b.intVal))
      elif a.kind in [vmInt, vmFloat] and b.kind in [vmInt, vmFloat]:
        let af = if a.kind == vmInt: a.intVal.float else: a.floatVal
        let bf = if b.kind == vmInt: b.intVal.float else: b.floatVal
        vm.push(VMValue(kind: vmFloat, floatVal: af * bf))
      else:
        vm.push(VMValue(kind: vmNull))

    of opNegate:
      let v = vm.pop()
      vm.pop_and_record()
      vm.push_path("")
      if v.kind == vmInt:
        vm.push(VMValue(kind: vmInt, intVal: -v.intVal))
      elif v.kind == vmFloat:
        vm.push(VMValue(kind: vmFloat, floatVal: -v.floatVal))
      else:
        vm.push(VMValue(kind: vmNull))

    of opGetIndex:
      let index = vm.pop()
      let idx_path = vm.pop_path()
      let arr = vm.pop()
      let arr_path = vm.pop_path()

      case arr.kind
      of vmArray:
        if index.kind == vmInt:
          let idx = index.intVal
          if idx >= 0 and idx < arr.arrayVal.len:
            vm.push(arr.arrayVal[idx])
          elif idx < 0 and -idx <= arr.arrayVal.len:
            # Support negative indexing
            vm.push(arr.arrayVal[arr.arrayVal.len + idx])
          else:
            vm.push(VMValue(kind: vmNull))
        else:
          vm.push(VMValue(kind: vmNull))
        # Track: items[0] or items[-1]
        if vm.track_access:
          if arr_path.len > 0 and index.kind == vmInt:
            vm.push_path(arr_path & "[" & $index.intVal & "]")
          else:
            vm.push_path("")
      of vmObject:
        # For objects, convert index to string key
        let key = index.to_string()
        if key in arr.objectVal:
          vm.push(arr.objectVal[key])
        else:
          vm.push(VMValue(kind: vmNull))
        # Track: obj["key"] → obj.key
        if vm.track_access:
          if arr_path.len > 0:
            vm.push_path(arr_path & "." & key)
          else:
            vm.push_path("")
      else:
        vm.push(VMValue(kind: vmNull))
        vm.push_path("")
      # Record index path if it came from context
      if vm.track_access and idx_path.len > 0:
        vm.accessed_paths.incl(idx_path)

    # Filters
    of opCallFilter:
      # Pop arguments (they were pushed in order during compilation)
      var args: seq[VMValue] = @[]
      for i in uint8(0)..<inst.argCount:
        args.add(vm.pop())
        vm.pop_and_record()  # Record each arg's path

      # Arguments are popped in reverse order, so reverse them back
      args.reverse()

      # Pop the value to filter
      let value = vm.pop()
      vm.pop_and_record()  # Record the value's path

      # A filter error propagates to the caller as-is; a library must not
      # echo to the host program's console on the way out.
      vm.push(apply_filter(value, vm.strings[inst.filterId], args))
      vm.push_path("")  # Filter result is computed, not direct context
    
    of opRange:
      # Create a range from start..end (lenient: bad values become 0)
      let end_int = vm.pop().to_int64(strict = false)
      let start_int = vm.pop().to_int64(strict = false)
      vm.pop2_record_push0()

      # Create array with range values (empty if start > end)
      var range_array: seq[VMValue] = @[]
      if start_int <= end_int:
        for i in start_int..end_int:
          range_array.add(VMValue(kind: vmInt, intVal: i))

      vm.push(VMValue(kind: vmArray, arrayVal: range_array))

    # Logical operators
    of opAnd:
      let b = vm.pop()
      let a = vm.pop()
      vm.pop2_record_push0()
      vm.push(VMValue(kind: vmBool, boolVal: a.is_truthy() and b.is_truthy()))

    of opOr:
      let b = vm.pop()
      let a = vm.pop()
      vm.pop2_record_push0()
      vm.push(VMValue(kind: vmBool, boolVal: a.is_truthy() or b.is_truthy()))

    of opNot:
      let v = vm.pop()
      vm.pop_and_record()
      vm.push_path("")
      vm.push(VMValue(kind: vmBool, boolVal: not v.is_truthy()))

    of opInclude:
      # Pop stack arguments
      var partialName: string
      if inst.includeVarExpr:
        partialName = vm.pop().to_string()
        vm.pop_and_record()
      else:
        partialName = vm.strings[inst.templateId]

      var kwArgs: seq[(string, VMValue)] = @[]
      for i in countdown(inst.includeArgNames.len - 1, 0):
        let val = vm.pop()
        vm.pop_and_record()
        kwArgs.add((vm.strings[inst.includeArgNames[i]], val))

      var withVal = VMValue(kind: vmNull)
      if inst.includeWithVar >= 0:
        withVal = vm.pop()
        vm.pop_and_record()

      var forCollection: seq[VMValue] = @[]
      let hasForLoop = inst.includeForVar >= 0
      if hasForLoop:
        let collVal = vm.pop()
        vm.pop_and_record()
        if collVal.kind == vmArray:
          forCollection = collVal.arrayVal

      # Compile partial (with caching)
      let indent = if inst.includeHasIndent: vm.strings[inst.includeIndentId] else: ""
      let partial = vm.compile_partial(partialName, indent)
      if not partial.found:
        discard  # Missing partial outputs nothing
      elif hasForLoop:
        # Iterate over collection, executing partial for each item
        for idx, item in forCollection:
          var sub = vm.create_sub_vm(partial.bytecode, partial.strings,
                                     partial.constants, inst.withContext)
          sub.locals[partialName] = item
          sub.bind_keyword_args(kwArgs, inst.withContext)
          let forloop = build_forloop(idx, forCollection.len, "", vm_null())
          # Use variables (not locals) so inner for-loops don't pick it up as parentloop
          if inst.withContext: sub.locals["forloop"] = forloop
          else: sub.variables["forloop"] = forloop
          vm.emit_output(sub.execute())
          vm.propagate_scope(sub, inst.withContext, propagate_control = false)
      else:
        # Single execution
        var sub = vm.create_sub_vm(partial.bytecode, partial.strings,
                                   partial.constants, inst.withContext)
        if inst.includeWithVar >= 0:
          let alias = if inst.includeAlias >= 0: vm.strings[inst.includeAlias.uint32]
                      else: partialName
          sub.locals[alias] = withVal
        sub.bind_keyword_args(kwArgs, inst.withContext)
        vm.emit_output(sub.execute())
        vm.propagate_scope(sub, inst.withContext)

    of opBreak:
      # Break outside a loop (e.g. from an included partial)
      # Set pending_break flag and stop execution — parent will handle
      vm.pending_break = true
      break  # Stop executing this partial

    of opContinue:
      # Continue outside a loop (e.g. from an included partial)
      vm.pending_continue = true
      break  # Stop executing this partial

    else:
      # Unimplemented opcode
      raise newException(CatchableError,
        "Unimplemented opcode: " & $inst.op)

  # Hand the buffer over rather than copying the whole rendered page: the
  # VM takes a var parameter, so ARC cannot infer the move on its own, and
  # no caller reads output after execute returns.
  result = move(vm.output)
