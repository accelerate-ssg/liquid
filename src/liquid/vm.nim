# Liquid VM Executor: Bytecode + Data -> Text
# ============================================
# Takes compiled bytecode and runtime data, produces output

import compiler/[types]
import vm/[types]
import std/[tables, strutils, sequtils, algorithm, sets]
import arena_context_store
import value_ops
import filters
import types as lexer_types
import lexer
import compiler

# Forward declaration
proc register_liquid_tag_handlers*(vm: var LiquidVM)

# Create VM with data
proc new_liquid_vm*(bytecode: seq[Instruction], strings: seq[string],
                  constants: seq[VMValue], context: ptr Table[string, VMValue],
                  partials: ptr Table[string, string] = nil,
                  arena: ptr Arena = nil,
                  context_root: NodeId = InvalidNodeId): LiquidVM =
  ## The context and partials are borrowed, not copied: the VM never writes
  ## through either pointer, and both must outlive the VM. Every caller here
  ## satisfies that — a VM lives entirely inside one render call, and a
  ## sub-VM inside its parent's.
  ## The tables are left to default-initialise. initTable eagerly allocates
  ## 32 slots each, which was most of the cost of building a VM, and most
  ## of them stay empty for a whole render — a template with no {% assign %}
  ## never writes a local. Nim allocates them on first insert instead, and
  ## reads of an empty table just miss.
  result = LiquidVM(
    stack: newSeqOfCap[VMValue](32),
    pc: 0,
    bytecode: bytecode,
    strings: strings,
    constants: constants,
    context: context,
    arena: arena,
    context_root: context_root,
    iterators: @[],
    output: "",
    escape_html: false,
    capture_stack: @[],
    is_capturing: false,
    partials: partials,
    pending_break: false,
    pending_continue: false,
    instruction_count: 0,
    max_stack_size: 0
  )
  # `new` rather than newTable: the shared tables need a cell to share, but
  # not the 32 slots newTable would allocate up front. The table inside
  # fills itself on first insert, and most of these stay empty.
  new(result.locals)
  new(result.loop_offsets)
  new(result.partial_cache)
  result.register_liquid_tag_handlers()

# Stack operations
template push(vm: var LiquidVM, val: VMValue) =
  vm.stack.add(val)
  vm.max_stack_size = max(vm.max_stack_size, vm.stack.len)

template pop(vm: var LiquidVM): VMValue =
  if vm.stack.len > 0:
    vm.stack.pop()
  else:
    VMValue(kind: vmNull)

template peek(vm: LiquidVM, offset: int = 0): VMValue =
  if vm.stack.len > offset:
    vm.stack[vm.stack.len - 1 - offset]
  else:
    VMValue(kind: vmNull)

# ─── Arena-backed lazy values ────────────────────────────────────────
#
# Container nodes travel through the VM as vmNode — just a NodeId — and
# resolve against the arena on access, so an alias like
# {% assign s = site %} costs nothing and s.title records the same
# precise edge read site.title would. Scalars are always wrapped
# eagerly, so every numeric, string, bool and null code path in the VM
# behaves identically whether a value came from the arena or not.

proc wrap_arena_node*(arena: Arena, id: NodeId): VMValue =
  ## Scalars come back eager; containers stay lazy. A missing node is
  ## null, matching Liquid's undefined semantics.
  if id == InvalidNodeId:
    return VMValue(kind: vmNull)
  case arena.kind(id)
  of nkNull: VMValue(kind: vmNull)
  of nkBool: VMValue(kind: vmBool, boolVal: arena.getBool(id))
  of nkInt: VMValue(kind: vmInt, intVal: arena.getInt(id))
  of nkFloat: VMValue(kind: vmFloat, floatVal: arena.getFloat(id))
  of nkString: VMValue(kind: vmString, stringVal: arena.getStr(id))
  of nkArray, nkObject: VMValue(kind: vmNode, nodeVal: uint32(id))

proc wrap_node(vm: LiquidVM, id: NodeId): VMValue =
  wrap_arena_node(vm.arena[], id)

proc materialize_node(vm: LiquidVM, id: NodeId): VMValue =
  ## Deep-convert an arena subtree into an eager value. Records reads of
  ## everything it touches — honest, because the caller consumes the
  ## whole value (filters, comparisons, stringification).
  let arena = vm.arena
  case arena[].kind(id)
  of nkNull: VMValue(kind: vmNull)
  of nkBool: VMValue(kind: vmBool, boolVal: arena[].getBool(id))
  of nkInt: VMValue(kind: vmInt, intVal: arena[].getInt(id))
  of nkFloat: VMValue(kind: vmFloat, floatVal: arena[].getFloat(id))
  of nkString: VMValue(kind: vmString, stringVal: arena[].getStr(id))
  of nkArray:
    var v = VMValue(kind: vmArray)
    for child in arrItems(arena[], id):
      v.arrayVal.add(vm.materialize_node(child))
    v
  of nkObject:
    var v = VMValue(kind: vmObject)
    for key, child in objPairs(arena[], id):
      v.objectVal[key] = vm.materialize_node(child)
    v

proc materialize(vm: LiquidVM, v: VMValue): VMValue =
  ## Resolve a lazy value into an eager one at the boundaries that
  ## consume values wholesale; anything already eager passes through.
  if v.kind == vmNode:
    vm.materialize_node(NodeId(v.nodeVal))
  else:
    v

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
  # Shopify semantics: ordering incompatible types is an error (equality
  # is merely false). Naming the kinds turns a hunt into a glance.
  raise newException(ValueError, "comparison of incompatible types: " &
    $a.kind & " <=> " & $b.kind)

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

template emit_output(vm: var LiquidVM, str: string) =
  ## Emit text to current output target (capture stack or main output)
  if vm.is_capturing:
    vm.capture_stack[^1].add(str)
  else:
    vm.output.add(str)

proc build_forloop*(idx0, length: int, name: string, parent: VMValue): VMValue =
  ## Build a forloop helper object for Liquid {% for %} loops
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
  if parent.kind != vm_null:
    obj["parentloop"] = parent
  else:
    obj["parentloop"] = vm_null()
  vm_object(obj)

proc build_tablerowloop*(idx, total, cols: int): VMValue =
  ## Build a tablerowloop helper object for Liquid {% tablerow %} tags.
  ## An exhausted or empty tablerow still has to describe a cell without
  ## dividing by zero, hence the floor of one column.
  let effective_cols = if cols > 0: cols elif total > 0: total else: 1
  let col0 = idx mod effective_cols
  vm_object({
    "col": vm_int((col0 + 1).int64),
    "col0": vm_int(col0.int64),
    "col_first": vm_bool(col0 == 0),
    "col_last": vm_bool(col0 == effective_cols - 1 or idx == total - 1),
    "first": vm_bool(idx == 0),
    "index": vm_int((idx + 1).int64),
    "index0": vm_int(idx.int64),
    "last": vm_bool(idx == total - 1),
    "length": vm_int(total.int64),
    "rindex": vm_int((total - idx).int64),
    "rindex0": vm_int((total - idx - 1).int64),
    "row": vm_int(((idx div effective_cols) + 1).int64),
  }.toOrderedTable)

proc current_tablerowloop(vm: var LiquidVM): VMValue =
  ## The innermost active tablerow's cell metadata, cached per cell.
  let state = addr vm.tablerow_iters[^1]
  if not state.tablerowloop_valid:
    state.tablerowloop_cache =
      build_tablerowloop(state.index, state.items.len, state.cols)
    state.tablerowloop_valid = true
  state.tablerowloop_cache

proc current_forloop(vm: var LiquidVM): VMValue =
  ## The innermost active loop's metadata, built on first ask and cached
  ## until the iteration advances. Most loop bodies never mention forloop,
  ## and building the object cost more than the rest of an iteration, so
  ## the loop itself no longer builds one.
  let iter = addr vm.iterators[^1]
  if not iter.forloop_valid:
    iter.forloop_cache = build_forloop(iter.index - 1, iter.items.len,
                                       iter.loop_name, iter.saved_forloop)
    iter.forloop_valid = true
  iter.forloop_cache

proc resolve_var*(vm: var LiquidVM, name: string): VMValue =
  ## Resolve a variable name through the scope chain:
  ## keyword_args → active loop → locals → context → variables →
  ## arena context → counters → null
  ##
  ## Each level uses withValue rather than `in` followed by `[]`: the pair
  ## hashes the name and probes the table twice for every level that hits.
  ## A level that holds an explicit null must still shadow the levels below
  ## it, so getOrDefault is not an option — presence is what we test.
  ##
  ## An active loop outranks locals because the loop used to overwrite
  ## locals["forloop"] on every iteration, so it won there too — including
  ## over a forloop an enclosing {% render %} had bound.
  vm.keyword_args.withValue(name, found): return found[]
  if vm.iterators.len > 0 and name == "forloop":
    return vm.current_forloop()
  if vm.tablerow_iters.len > 0 and name == "tablerowloop":
    return vm.current_tablerowloop()
  vm.locals[].withValue(name, found): return found[]
  if vm.context != nil:
    vm.context[].withValue(name, found): return found[]
  vm.variables.withValue(name, found): return found[]
  if vm.arena != nil and vm.context_root != InvalidNodeId:
    let child = vm.arena[].objGet(vm.context_root, name)
    if child != InvalidNodeId:
      return vm.wrap_node(child)
  vm.counters.withValue(name, found): return VMValue(kind: vmInt, intVal: found[])
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

proc finish_iterator*(vm: var LiquidVM, iter_index: int = -1) =
  ## Clean up a finished iterator: save offset, remove from stack, delete
  ## loop variable from locals. The enclosing loop's forloop needs no
  ## restoring — popping this iterator is what brings it back into view.
  let idx = if iter_index < 0: vm.iterators.len - 1 else: iter_index
  let finished = vm.iterators[idx]
  vm.loop_offsets[finished.var_name] = finished.original_offset + finished.items.len
  vm.iterators.delete(idx)
  vm.locals.del(finished.var_name)

# ─── Partial Execution Helpers ───────────────────────────────────────

proc compile_partial*(vm: var LiquidVM, name: string):
    tuple[bytecode: seq[Instruction], strings: seq[string],
          constants: seq[VMValue], found: bool] =
  ## Look up partial source, compile on first use, cache result.
  ## Returns found=false if partial doesn't exist.
  if vm.partials == nil or name notin vm.partials[]:
    result.found = false
    return
  if name notin vm.partial_cache:
    let source = vm.partials[][name]
    let sections = lex(source)
    let compiled = compile(sections, source, false)
    vm.partial_cache[name] = CompiledPartial(bytecode: compiled.bytecode,
      strings: compiled.strings, constants: compiled.constants)
  let cached = vm.partial_cache[name]
  result = (cached.bytecode, cached.strings, cached.constants, true)

proc create_sub_vm*(vm: var LiquidVM, bytecode: seq[Instruction],
                    strings: seq[string], constants: seq[VMValue],
                    shared_scope: bool): LiquidVM =
  ## Create a sub-VM for partial execution.
  ## shared_scope=true (include): shares context, locals, loop_offsets, counters
  ## shared_scope=false (render): isolated empty scope
  ##
  ## The shared case borrows the parent's context pointer and shares its
  ## locals by reference rather than copying either, so an include costs
  ## nothing per variable already in scope.
  ##
  ## counters is the exception and is deliberately still copied: the
  ## {% include 'x' for collection %} path calls propagate_scope with
  ## propagate_control = false to discard the partial's counters on every
  ## iteration, so sharing them would make {% increment %} inside such a
  ## partial persist across iterations. The table is small and holds no
  ## nested data.
  result = new_liquid_vm(bytecode, strings, constants,
    if shared_scope: vm.context else: nil,
    vm.partials)
  if shared_scope:
    # Carries a {% render %} forloop down through a nested include.
    result.variables = vm.variables
    result.locals = vm.locals
    result.loop_offsets = vm.loop_offsets
    result.counters = vm.counters
    # The arena context is part of the shared scope: reads inside the
    # partial record like the parent's own, so tracking stays transitive.
    result.arena = vm.arena
    result.context_root = vm.context_root
  result.partial_cache = vm.partial_cache

proc propagate_scope*(vm: var LiquidVM, sub: LiquidVM,
                      shared_scope: bool, propagate_control: bool = true) =
  ## Propagate state from sub-VM back to parent.
  ## Only propagates for include (shared_scope=true).
  ## propagate_control=true also copies counters and break/continue flags.
  ##
  ## The partial cache needs no write-back: parent and sub-VM share one
  ## table, so anything the partial compiled is already visible here.
  if shared_scope:
    # locals and loop_offsets need no write-back — they are the parent's
    # own tables, which the sub-VM has been writing through all along.
    if propagate_control:
      vm.counters = sub.counters
      if sub.pending_break: vm.pending_break = true
      if sub.pending_continue: vm.pending_continue = true

proc bind_keyword_args*(sub: var LiquidVM,
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

# ─── Liquid Tag Runtime Handlers ──────────────────────────────────────

proc tag_increment(vm: var LiquidVM, inst: Instruction) =
  ## {% increment var %} - output current counter value, then increment
  let var_name = vm.strings[inst.tagData[0]]
  let current = vm.counters.getOrDefault(var_name, 0'i64)
  vm.emit_output($current)
  vm.counters[var_name] = current + 1

proc tag_decrement(vm: var LiquidVM, inst: Instruction) =
  ## {% decrement var %} - decrement counter, then output
  let var_name = vm.strings[inst.tagData[0]]
  let current = vm.counters.getOrDefault(var_name, 0'i64)
  let new_val = current - 1
  vm.counters[var_name] = new_val
  vm.emit_output($new_val)

proc tag_cycle(vm: var LiquidVM, inst: Instruction) =
  ## {% cycle [group:] val1, val2, ... %} - output next value in cycle
  # tagData layout: [groupId, groupIsVar, cycleKey, argCount]
  let group_id = inst.tagData[0]
  let group_is_var = inst.tagData[1] != 0
  let cycle_key = inst.tagData[2]
  let arg_count = inst.tagData[3].int

  # Pop cycle values from stack (in reverse order since stack is LIFO)
  var values: seq[VMValue] = newSeq[VMValue](arg_count)
  for i in countdown(arg_count - 1, 0):
    values[i] = vm.pop()

  # Determine the group key
  var group_key: string
  if group_id >= 0:
    if group_is_var:
      group_key = vm.materialize(vm.resolve_var(vm.strings[group_id.uint32])).to_string()
    else:
      group_key = vm.strings[group_id.uint32]
  else:
    group_key = vm.strings[cycle_key.uint32]

  # Get current iteration index for this group
  let iteration = vm.cycle_counters.getOrDefault(group_key, 0)
  if arg_count > 0:
    if iteration < arg_count:
      vm.emit_output(vm.materialize(values[iteration]).to_string())
    var next = iteration + 1
    if next >= arg_count:
      next = 0
    vm.cycle_counters[group_key] = next

proc tag_ifchanged_begin(vm: var LiquidVM, inst: Instruction) =
  ## {% ifchanged %} - start capturing output for comparison
  vm.capture_stack.add("")
  vm.is_capturing = true
  vm.capture_escape_stack.add(vm.escape_html)
  vm.escape_html = false

proc tag_ifchanged_end(vm: var LiquidVM, inst: Instruction) =
  ## End ifchanged block - compare captured output with previous
  if vm.capture_stack.len > 0:
    let captured = vm.capture_stack.pop()
    vm.is_capturing = vm.capture_stack.len > 0
    if vm.capture_escape_stack.len > 0:
      vm.escape_html = vm.capture_escape_stack.pop()
    if captured != vm.ifchanged_last:
      vm.ifchanged_last = captured
      vm.emit_output(captured)

proc tag_tablerow_begin(vm: var LiquidVM, inst: Instruction) =
  ## {% tablerow var in collection %} - begin tablerow loop
  # tagData layout: [varIndex, hasCols, hasLimit, hasOffset]
  let var_index = inst.tagData[0]
  let has_cols = inst.tagData[1] != 0
  let has_limit = inst.tagData[2] != 0
  let has_offset = inst.tagData[3] != 0

  var cols_val = 0
  var limit_val = -1'i64
  var offset_val = 0'i64

  if has_cols:
    let cv = vm.pop()
    case cv.kind
    of vmInt: cols_val = cv.intVal.int
    of vmFloat: cols_val = cv.floatVal.int
    of vmString:
      try: cols_val = parseInt(cv.stringVal)
      except ValueError: discard
    else: discard

  if has_limit:
    let lv = vm.pop()
    case lv.kind
    of vmInt: limit_val = lv.intVal
    of vmFloat: limit_val = lv.floatVal.int64
    of vmString:
      try: limit_val = parseInt(lv.stringVal).int64
      except ValueError: discard
    of vmNull: limit_val = 0
    else: discard

  if has_offset:
    let ov = vm.pop()
    case ov.kind
    of vmInt: offset_val = ov.intVal
    of vmFloat: offset_val = ov.floatVal.int64
    of vmString:
      try: offset_val = parseInt(ov.stringVal).int64
      except ValueError: discard
    of vmNull: offset_val = 0
    else: discard

  let collection = vm.pop()
  var items: seq[VMValue] = @[]

  case collection.kind
  of vmArray: items = collection.arrayVal
  of vmObject:
    for key, val in collection.objectVal:
      items.add(VMValue(kind: vmArray, arrayVal: @[
        VMValue(kind: vmString, stringVal: key), val]))
  of vmNode:
    let arena = vm.arena
    let id = NodeId(collection.nodeVal)
    case arena[].kind(id)
    of nkArray:
      for child in arrItems(arena[], id):
        items.add(vm.wrap_node(child))
    of nkObject:
      for key, child in objPairs(arena[], id):
        items.add(VMValue(kind: vmArray, arrayVal: @[
          VMValue(kind: vmString, stringVal: key), vm.wrap_node(child)]))
    else: discard
  else: discard

  # Apply offset
  if offset_val > 0 and offset_val < items.len.int64:
    items = items[offset_val..^1]
  elif offset_val >= items.len.int64:
    items = @[]

  # Apply limit
  if limit_val >= 0 and limit_val < items.len.int64:
    items = items[0..<limit_val]

  if items.len == 0:
    vm.tablerow_iters.add(TablerowState(
      items: @[], index: 0, cols: cols_val,
      var_name: vm.strings[var_index]))
  else:
    let var_name = vm.strings[var_index]
    vm.tablerow_iters.add(TablerowState(
      items: items, index: 0, cols: cols_val, var_name: var_name))
    vm.locals[var_name] = items[0]
    vm.emit_output("<tr class=\"row1\">\n<td class=\"col1\">")

proc tag_tablerow_iter(vm: var LiquidVM, inst: Instruction) =
  ## Tablerow iteration - handle cell closing, row wrapping, iteration
  # tagData layout: [endOffset, bodyOffset]
  let end_offset = inst.tagData[0]
  let body_offset = inst.tagData[1]

  if vm.tablerow_iters.len == 0:
    vm.pc += end_offset
  else:
    let state = addr vm.tablerow_iters[^1]
    if state.items.len == 0:
      vm.tablerow_iters.setLen(vm.tablerow_iters.len - 1)
      vm.pc += end_offset
    else:
      vm.emit_output("</td>")
      state.index += 1
      state.tablerowloop_valid = false
      if state.index >= state.items.len:
        vm.emit_output("</tr>\n")
        vm.locals.del(state.var_name)
        vm.tablerow_iters.setLen(vm.tablerow_iters.len - 1)
        vm.pc += end_offset
      else:
        let total = state.items.len
        let idx = state.index
        let effective_cols = if state.cols > 0: state.cols else: total
        let col0 = idx mod effective_cols
        let col = col0 + 1
        let row = (idx div effective_cols) + 1
        var html = ""
        if col0 == 0:
          html.add("</tr>\n<tr class=\"row" & $row & "\">")
        html.add("<td class=\"col" & $col & "\">")
        vm.emit_output(html)
        vm.locals[state.var_name] = state.items[idx]
        vm.pc += body_offset

proc register_liquid_tag_handlers*(vm: var LiquidVM) =
  ## Register all Liquid tag runtime handlers
  vm.tag_handlers["increment"] = tag_increment
  vm.tag_handlers["decrement"] = tag_decrement
  vm.tag_handlers["cycle"] = tag_cycle
  vm.tag_handlers["ifchanged_begin"] = tag_ifchanged_begin
  vm.tag_handlers["ifchanged_end"] = tag_ifchanged_end
  vm.tag_handlers["tablerow_begin"] = tag_tablerow_begin
  vm.tag_handlers["tablerow_iter"] = tag_tablerow_iter

# Main execution function
proc execute*(vm: var LiquidVM): string =
  ## Execute the bytecode and return the output
  
  while vm.pc < vm.bytecode.len:
    # A cursor borrows the instruction instead of copying 48 bytes per
    # dispatch. Safe only because no branch below moves a seq out of it —
    # tagData and includeArgNames are read by index, never iterated into a
    # temporary, and the bytecode is never written during execution.
    let inst {.cursor.} = vm.bytecode[vm.pc]
    inc vm.pc
    inc vm.instruction_count

    # When pending break/continue is active, skip all instructions except
    # opIterNext (which handles the break/continue) and opStoreVar (to pop stack)
    if (vm.pending_break or vm.pending_continue) and inst.op != opIterNext:
      # Skip instructions, but pop any stack values that were pushed
      case inst.op
      of opStoreVar:
        discard vm.pop()
      else:
        discard
      continue

    case inst.op
    # Stack operations
    of opPushNull:
      vm.push(VMValue(kind: vmNull))

    of opPushEmpty:
      vm.push(VMValue(kind: vmEmpty))

    of opPushTrue:
      vm.push(VMValue(kind: vmBool, boolVal: true))

    of opPushFalse:
      vm.push(VMValue(kind: vmBool, boolVal: false))

    of opPushInt:
      vm.push(VMValue(kind: vmInt, intVal: inst.intVal))

    of opPushFloat:
      vm.push(VMValue(kind: vmFloat, floatVal: inst.floatVal))

    of opPushString:
      vm.push(VMValue(kind: vmString, stringVal: vm.strings[inst.stringId]))

    of opPop:
      discard vm.pop()

    of opDup:
      if vm.stack.len > 0:
        vm.push(vm.peek())

    # Variable operations
    of opLoadVar:
      let name = vm.strings[inst.stringId]
      vm.push(vm.resolve_var(name))

    of opDynamicLoadVar:
      # Pop key from stack, use it as a variable name
      let name = vm.materialize(vm.pop()).to_string()
      vm.push(vm.resolve_var(name))

    of opStoreVar:
      let var_name = vm.strings[inst.stringId]
      let value = vm.pop()
      vm.locals[var_name] = value

    # Property access
    of opGetProp:
      let obj = vm.pop()
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
      of vmNode:
        # Lazy container: resolve one edge in the arena, mirroring the
        # eager branches above, including the virtual properties.
        let arena = vm.arena
        let id = NodeId(obj.nodeVal)
        case arena[].kind(id)
        of nkObject:
          let child = arena[].objGet(id, prop_name)
          if child != InvalidNodeId:
            vm.push(vm.wrap_node(child))
          else:
            case prop_name
            of "size", "length":
              vm.push(VMValue(kind: vmInt, intVal: arena[].objLen(id).int64))
            of "first":
              if arena[].objLen(id) > 0:
                vm.push(VMValue(kind: vmArray, arrayVal: @[
                  VMValue(kind: vmString, stringVal: arena[].objGetKey(id, 0)),
                  vm.wrap_node(arena[].objGetVal(id, 0))]))
              else:
                vm.push(VMValue(kind: vmNull))
            else:
              vm.push(VMValue(kind: vmNull))
        of nkArray:
          case prop_name
          of "size", "length":
            vm.push(VMValue(kind: vmInt, intVal: arena[].arrLen(id).int64))
          of "first":
            vm.push(vm.wrap_node(arena[].arrGetOrMiss(id, 0)))
          of "last":
            let length = arena[].arrLen(id)
            if length > 0:
              vm.push(vm.wrap_node(arena[].arrGet(id, length - 1)))
            else:
              vm.push(VMValue(kind: vmNull))
          else:
            vm.push(VMValue(kind: vmNull))
        else:
          vm.push(VMValue(kind: vmNull))
      else:
        vm.push(VMValue(kind: vmNull))

    # Output operations
    of opOutput:
      # Values render straight into the target buffer. Going through
      # to_string first copied the value's text once to build the string
      # and again to append it; an integer allocated a string just to be
      # thrown away. Only escaping still needs an intermediate, and it is
      # off by default.
      var val = vm.pop()
      # Lazy values materialize here: stringification consumes the value.
      if val.kind == vmNode:
        val = vm.materialize_node(NodeId(val.nodeVal))

      if vm.is_capturing:
        # When capturing, store raw (escaping happens on final output)
        vm.capture_stack[^1].add_to_string(val)
      elif vm.escape_html:
        vm.output.add(val.to_string().escape_html_str())
      else:
        vm.output.add_to_string(val)
      
    of opBatchOutput:
      # Literal template text - NEVER escape
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
      # Runtime dispatch to registered tag handler
      let tag_name = vm.strings[inst.tagId]
      if tag_name in vm.tag_handlers:
        vm.tag_handlers[tag_name](vm, inst)
      else:
        raise newException(CatchableError, "Unknown tag handler: " & tag_name)

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
      if not cond.is_truthy():
        vm.pc += inst.offset

    of opJumpIfTrue:
      let cond = vm.pop()
      if cond.is_truthy():
        vm.pc += inst.offset
    
    # Loops
    of opBeginLoop:
      # Pop limit and offset values if present (limit is on top, then offset, then collection)
      var limit_val = -1'i64  # -1 means no limit
      var offset_val = 0'i64  # 0 means no offset

      if inst.hasLimit:
        limit_val = vm.pop().to_int64()

      if inst.hasOffset:
        offset_val = vm.pop().to_int64()

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
      var items: seq[VMValue] = @[]

      case collection.kind
      of vmArray:
        items = collection.arrayVal
      of vmObject:
        # Convert object to array of key-value pairs
        for key, val in collection.objectVal:
          items.add(VMValue(kind: vmArray, arrayVal: @[
            VMValue(kind: vmString, stringVal: key),
            val
          ]))
      of vmNode:
        # Lazy container: expand to wrapped elements. The iteration is
        # recorded in the arena, and each element stays lazy until used.
        let arena = vm.arena
        let id = NodeId(collection.nodeVal)
        case arena[].kind(id)
        of nkArray:
          for child in arrItems(arena[], id):
            items.add(vm.wrap_node(child))
        of nkObject:
          for key, child in objPairs(arena[], id):
            items.add(VMValue(kind: vmArray, arrayVal: @[
              VMValue(kind: vmString, stringVal: key),
              vm.wrap_node(child)
            ]))
        else:
          discard
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

      # Snapshot the enclosing forloop as this loop's parentloop. The new
      # iterator is not on the stack yet, so this reads the parent. Once per
      # loop, not once per iteration: the parent cannot advance while this
      # loop runs.
      #
      # Deliberately not a full resolve_var — a forloop bound by an
      # enclosing {% render %} lives in variables precisely so that loops
      # inside the partial do not adopt it as their parentloop.
      let saved_fl =
        if vm.iterators.len > 0: vm.current_forloop()
        else: vm.locals.getOrDefault("forloop", vm_null())

      # Get loop name from instruction
      let loop_name = if inst.loopNameId >= 0: vm.strings[inst.loopNameId] else: ""

      vm.iterators.add(Iterator(
        items: items,
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
            iter.index += 1
            iter.forloop_valid = false
          else:
            vm.finish_iterator()
            vm.pc += inst.endOffset
        else:
          # Normal iteration
          var iter = addr vm.iterators[^1]
          if iter.index < iter.items.len:
            vm.push(iter.items[iter.index])
            iter.index += 1
            iter.forloop_valid = false
          else:
            let wasEmpty = iter.index == 0
            vm.finish_iterator()
            if wasEmpty and inst.elseOffset != 0:
              vm.pc += inst.elseOffset
            else:
              vm.pc += inst.endOffset
    
    # Comparison
    of opEqual:
      # Equality consumes both values wholesale, so lazy ones materialize.
      let b = vm.materialize(vm.pop())
      let a = vm.materialize(vm.pop())
      vm.push(VMValue(kind: vmBool, boolVal: liquid_eq(a, b)))

    of opNotEqual:
      let b = vm.materialize(vm.pop())
      let a = vm.materialize(vm.pop())
      vm.push(VMValue(kind: vmBool, boolVal: not liquid_eq(a, b)))

    of opLess:
      let b = vm.pop()
      let a = vm.pop()
      vm.push(VMValue(kind: vmBool, boolVal: liquid_compare(a, b) < 0))

    of opLessEqual:
      let b = vm.pop()
      let a = vm.pop()
      vm.push(VMValue(kind: vmBool, boolVal: liquid_compare(a, b) <= 0))

    of opGreater:
      let b = vm.pop()
      let a = vm.pop()
      vm.push(VMValue(kind: vmBool, boolVal: liquid_compare(a, b) > 0))

    of opGreaterEqual:
      let b = vm.pop()
      let a = vm.pop()
      vm.push(VMValue(kind: vmBool, boolVal: liquid_compare(a, b) >= 0))
    
    of opContains:
      let needle = vm.materialize(vm.pop())  # What we're looking for
      let haystack = vm.materialize(vm.pop())  # Where we're looking

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

      if a.kind == vmInt and b.kind == vmInt:
        if b.intVal == 0:
          # Modulo by zero - push 0 or null
          vm.push(VMValue(kind: vmNull))
        else:
          vm.push(VMValue(kind: vmInt, intVal: a.intVal mod b.intVal))
      else:
        vm.push(VMValue(kind: vmNull))

    of opAdd:
      # Materialize so the string-concatenation path stringifies lazy
      # containers the same way it always stringified eager ones.
      let b = vm.materialize(vm.pop())
      let a = vm.materialize(vm.pop())

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
      if v.kind == vmInt:
        vm.push(VMValue(kind: vmInt, intVal: -v.intVal))
      elif v.kind == vmFloat:
        vm.push(VMValue(kind: vmFloat, floatVal: -v.floatVal))
      else:
        vm.push(VMValue(kind: vmNull))

    of opGetIndex:
      let index = vm.pop()
      let arr = vm.pop()

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
      of vmObject:
        # For objects, convert index to string key
        let key = index.to_string()
        if key in arr.objectVal:
          vm.push(arr.objectVal[key])
        else:
          vm.push(VMValue(kind: vmNull))
      of vmNode:
        let arena = vm.arena
        let id = NodeId(arr.nodeVal)
        case arena[].kind(id)
        of nkArray:
          if index.kind == vmInt:
            var idx = int(index.intVal)
            if idx < 0:
              # Negative indexing depends on the length, and the arena
              # records that dependency through arrLen.
              idx += arena[].arrLen(id)
            vm.push(vm.wrap_node(arena[].arrGetOrMiss(id, idx)))
          else:
            vm.push(VMValue(kind: vmNull))
        of nkObject:
          let key = index.to_string()
          vm.push(vm.wrap_node(arena[].objGet(id, key)))
        else:
          vm.push(VMValue(kind: vmNull))
      else:
        vm.push(VMValue(kind: vmNull))

    # Filters
    of opCallFilter:
      let filter_name = vm.strings[inst.filterId]

      # Pop arguments (they were pushed in order during compilation)
      var args: seq[VMValue] = @[]
      for i in uint8(0)..<inst.argCount:
        args.add(vm.pop())

      # Arguments are popped in reverse order, so reverse them back
      args.reverse()

      # Pop the value to filter. Filters have no arena access, so lazy
      # values (and lazy arguments) materialize at this boundary — the
      # filter consumes the whole value anyway.
      let value = vm.materialize(vm.pop())
      for i in 0 ..< args.len:
        args[i] = vm.materialize(args[i])

      # Apply filter using the filters module
      try:
        let filter_result = apply_filter(value, filter_name, args)
        vm.push(filter_result)
      except Exception as e:
        echo "Filter error: ", e.msg
        raise e  # Re-throw the exception so tests can catch it
    
    of opRange:
      # Create a range from start..end (lenient: bad values become 0)
      let end_int = vm.pop().to_int64(strict = false)
      let start_int = vm.pop().to_int64(strict = false)

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
      vm.push(VMValue(kind: vmBool, boolVal: a.is_truthy() and b.is_truthy()))

    of opOr:
      let b = vm.pop()
      let a = vm.pop()
      vm.push(VMValue(kind: vmBool, boolVal: a.is_truthy() or b.is_truthy()))

    of opNot:
      let v = vm.pop()
      vm.push(VMValue(kind: vmBool, boolVal: not v.is_truthy()))

    of opInclude:
      # Pop stack arguments
      var partialName: string
      if inst.includeVarExpr:
        partialName = vm.materialize(vm.pop()).to_string()
      else:
        partialName = vm.strings[inst.templateId]

      var kwArgs: seq[(string, VMValue)] = @[]
      for i in countdown(inst.includeArgNames.len - 1, 0):
        let val = vm.pop()
        kwArgs.add((vm.strings[inst.includeArgNames[i]], val))

      var withVal = VMValue(kind: vmNull)
      if inst.includeWithVar >= 0:
        withVal = vm.pop()

      var forCollection: seq[VMValue] = @[]
      let hasForLoop = inst.includeForVar >= 0
      if hasForLoop:
        let collVal = vm.pop()
        if collVal.kind == vmArray:
          forCollection = collVal.arrayVal

      # Compile partial (with caching)
      let partial = vm.compile_partial(partialName)
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

# Public API
proc render*(bytecode: seq[Instruction], strings: seq[string],
            constants: seq[VMValue], data: Table[string, VMValue],
            partials: Table[string, string] = initTable[string, string]()): string =
  ## Render a template with the given data.
  ##
  ## The VM borrows data and partials for the duration of the call rather
  ## than copying them, which is why it takes their addresses here: both
  ## parameters outlive the VM, which dies when this proc returns.
  var vm = new_liquid_vm(bytecode, strings, constants,
                         unsafeAddr data, unsafeAddr partials)
  result = vm.execute()

proc render*(bytecode: seq[Instruction], strings: seq[string],
            constants: seq[VMValue], arena: ptr Arena, context_root: NodeId,
            overlays: Table[string, VMValue] = initTable[string, VMValue](),
            partials: Table[string, string] = initTable[string, string]()): string =
  ## Render a template against an arena-backed context. Top-level
  ## variables resolve lazily from the root object, container values stay
  ## lazy until consumed, and every context access lands in the arena's
  ## access log under whichever consumer the caller has pushed. Overlays
  ## shadow the context root, for per-page values like item and items.
  var vm = new_liquid_vm(bytecode, strings, constants,
                         unsafeAddr overlays, unsafeAddr partials,
                         arena, context_root)
  result = vm.execute()

when isMainModule:
  import std/[unittest, sets]
  import lexer, compiler

  let empty_array:seq[string] = @[]

  # Helper to compile and run a template
  proc render_template(source: string, data: Table[string, VMValue]): string =
    let sections = lex(source)
    let compiled = compile(sections, source)
    result = render(compiled.bytecode, compiled.strings, compiled.constants, data)

  # Helper to create VMValue from various types
  # proc to_vm_value(x: int): VMValue = vmInt(x.int64)
  # proc to_vm_value(x: float): VMValue = vmFloat(x)
  # proc to_vm_value(x: string): VMValue = vmString(x)
  # proc to_vm_value(x: bool): VMValue = vmBool(x)
  proc to_vm_value(x: seq[int]): VMValue =
    var arr: seq[VMValue] = @[]
    for item in x:
      arr.add(vmInt(item.int64))
    vmArray(arr)

  proc to_vm_value(x: seq[string]): VMValue =
    var arr: seq[VMValue] = @[]
    for item in x:
      arr.add(vmString(item))
    vmArray(arr)

  # proc to_vm_value(x: seq[float]): VMValue =
  #   var arr: seq[VMValue] = @[]
  #   for item in x:
  #     arr.add(vmFloat(item))
  #   vmArray(arr)

  # proc to_vm_value(x: seq[bool]): VMValue =
  #   var arr: seq[VMValue] = @[]
  #   for item in x:
  #     arr.add(vmBool(item))
  #   vmArray(arr)

  # # For already converted VMValues
  # proc to_vm_value(x: seq[VMValue]): VMValue =
  #   vmArray(x)

  # Helper to create object VMValue
  proc make_object(pairs: varargs[(string, VMValue)]): VMValue =
    var obj = initOrderedTable[string, VMValue]()
    for (k, v) in pairs:
      obj[k] = v
    vmObject(obj)

  suite "VM Basic Output":
    test "Empty template":
      let source = ""
      let data = initTable[string, VMValue]()
      let output = render_template(source, data)
      check output == ""

    test "Plain text":
      let source = "Hello, World!"
      let data = initTable[string, VMValue]()
      let output = render_template(source, data)
      check output == "Hello, World!"

    test "Simple variable":
      let source = "Hello, {{ name }}!"
      let data = {"name": vmString("Alice")}.toTable
      let output = render_template(source, data)
      check output == "Hello, Alice!"

    test "Missing variable as empty":
      let source = "Hello, {{ name }}!"
      let data = initTable[string, VMValue]()
      let output = render_template(source, data)
      check output == "Hello, !"

    test "Integer output":
      let source = "Count: {{ count }}"
      let data = {"count": vmInt(42)}.toTable
      let output = render_template(source, data)
      check output == "Count: 42"

    test "Float output":
      let source = "Price: {{ price }}"
      let data = {"price": vmFloat(19.99)}.toTable
      let output = render_template(source, data)
      check output == "Price: 19.99"

    test "Boolean output":
      let source = "Active: {{ active }}"
      let data = {"active": vmBool(true)}.toTable
      let output = render_template(source, data)
      check output == "Active: true"

  suite "VM Property Access":
    test "Object property":
      let source = "Name: {{ user.name }}"
      let data = {
        "user": make_object(("name", vmString("Bob")))
      }.toTable
      let output = render_template(source, data)
      check output == "Name: Bob"

    test "Nested property":
      let source = "City: {{ user.address.city }}"
      let data = {
        "user": make_object(
          ("address", make_object(
            ("city", vmString("New York"))
          ))
        )
      }.toTable
      let output = render_template(source, data)
      check output == "City: New York"

    test "Missing property as empty":
      let source = "Age: {{ user.age }}"
      let data = {
        "user": make_object(("name", vmString("Charlie")))
      }.toTable
      let output = render_template(source, data)
      check output == "Age: "

    test "Array property - size":
      let source = "Items: {{ items.size }}"
      let data = {
        "items": to_vm_value(@[1, 2, 3])
      }.toTable
      let output = render_template(source, data)
      check output == "Items: 3"

  suite "VM Conditionals":
    test "Simple if - true":
      let source = "{% if show %}Visible{% endif %}"
      let data = {"show": vmBool(true)}.toTable
      let output = render_template(source, data)
      check output == "Visible"

    test "Simple if - false":
      let source = "{% if show %}Visible{% endif %}"
      let data = {"show": vmBool(false)}.toTable
      let output = render_template(source, data)
      check output == ""

    test "If-else":
      let source = "{% if logged_in %}Welcome{% else %}Please login{% endif %}"
      
      let data1 = {"logged_in": vmBool(true)}.toTable
      check render_template(source, data1) == "Welcome"
      
      let data2 = {"logged_in": vmBool(false)}.toTable
      check render_template(source, data2) == "Please login"

    test "Truthy values":
      let source = "{% if value %}Yes{% else %}No{% endif %}"

      # Truthy values (in Liquid, only nil and false are falsy)
      check render_template(source, {"value": vmInt(1)}.toTable) == "Yes"
      check render_template(source, {"value": vmString("text")}.toTable) == "Yes"
      check render_template(source, {"value": to_vm_value(@[1])}.toTable) == "Yes"
      check render_template(source, {"value": vmInt(0)}.toTable) == "Yes"
      check render_template(source, {"value": vmString("")}.toTable) == "Yes"
      check render_template(source, {"value": to_vm_value(empty_array)}.toTable) == "Yes"

      # Falsy values (only nil and false)
      check render_template(source, {"value": vmNull()}.toTable) == "No"
      check render_template(source, {"value": VMValue(kind: vmBool, boolVal: false)}.toTable) == "No"

    test "Comparison operators":
      let source = "{% if age > 18 %}Adult{% else %}Minor{% endif %}"
      
      check render_template(source, {"age": vmInt(21)}.toTable) == "Adult"
      check render_template(source, {"age": vmInt(18)}.toTable) == "Minor"
      check render_template(source, {"age": vmInt(16)}.toTable) == "Minor"

  suite "VM Loops":
    test "Simple for loop":
      let source = "{% for item in items %}{{ item }} {% endfor %}"
      let data = {
        "items": to_vm_value(@[1, 2, 3])
      }.toTable
      let output = render_template(source, data)
      check output == "1 2 3 "

    test "For loop with strings":
      let source = "{% for name in names %}Hello {{ name }}! {% endfor %}"
      let data = {
        "names": to_vm_value(@["Alice", "Bob"])
      }.toTable
      let output = render_template(source, data)
      check output == "Hello Alice! Hello Bob! "

    test "Empty loop":
      let source = "{% for item in items %}{{ item }}{% endfor %}Done"
      let data = {
        "items": to_vm_value(empty_array)
      }.toTable
      let output = render_template(source, data)
      check output == "Done"

    test "Loop with object properties":
      let source = "{% for user in users %}{{ user.name }}: {{ user.age }} {% endfor %}"
      let data = {
        "users": vmArray(@[
          make_object(
            ("name", vmString("Alice")),
            ("age", vmInt(30))
          ),
          make_object(
            ("name", vmString("Bob")),
            ("age", vmInt(25))
          )
        ])
      }.toTable
      let output = render_template(source, data)
      check output == "Alice: 30 Bob: 25 "

    test "Nested loops":
      let source = "{% for row in rows %}{% for col in row %}{{ col }} {% endfor %}| {% endfor %}"
      let data = {
        "rows": vmArray(@[
          to_vm_value(@[1, 2]),
          to_vm_value(@[3, 4])
        ])
      }.toTable
      
      let output = render_template(source, data)
      
      check output == "1 2 | 3 4 | "

  suite "VM Variables":
    test "Assign literal":
      let source = "{% assign x = 5 %}x = {{ x }}"
      let data = initTable[string, VMValue]()
      let output = render_template(source, data)
      check output == "x = 5"

    test "Assign from variable":
      let source = "{% assign copy = original %}{{ copy }}"
      let data = {"original": vmString("test")}.toTable
      let output = render_template(source, data)
      check output == "test"

    test "Assign overwrites":
      let source = "{% assign x = 1 %}First: {{ x }} {% assign x = 2 %}Second: {{ x }}"
      let data = initTable[string, VMValue]()
      let output = render_template(source, data)
      check output == "First: 1 Second: 2"

    test "Local shadows global":
      let source = "Global: {{ x }} {% assign x = 'local' %}Local: {{ x }}"
      let data = {"x": vmString("global")}.toTable
      let output = render_template(source, data)
      check output == "Global: global Local: local"

  suite "VM Capture":
    test "Simple capture":
      let source = "{% capture greeting %}Hello, {{ name }}!{% endcapture %}{{ greeting }}"
      let data = {"name": vmString("World")}.toTable
      let output = render_template(source, data)
      check output == "Hello, World!"

    test "Capture with multiple outputs":
      let source = """{% capture card %}<h1>{{ title }}</h1><p>{{ desc }}</p>{% endcapture %}{{ card }}"""
      let data = {
        "title": vmString("Test"),
        "desc": vmString("Description")
      }.toTable
      let output = render_template(source, data)
      check output == "<h1>Test</h1><p>Description</p>"

    test "Nested capture":
      let source = """{% capture outer %}[{% capture inner %}{{ x }}{% endcapture %}{{ inner }}]{% endcapture %}{{ outer }}"""
      let data = {"x": vmString("nested")}.toTable
      let output = render_template(source, data)
      check output == "[nested]"
    
    test "Capture without HTML escaping":
      let source = """{% capture card %}<h1>{{ title }}</h1><p>{{ desc }}</p>{% endcapture %}{{ card }}"""
      let data = {
        "title": vmString("Test"),
        "desc": vmString("Description")
      }.toTable
      
      # Render with HTML escaping disabled
      let sections = lex(source)
      let compiled = compile(sections, source)
      var vm = new_liquid_vm(compiled.bytecode, compiled.strings, compiled.constants, addr data)
      vm.escape_html = false  # Disable HTML escaping
      let output = vm.execute()
      
      check output == "<h1>Test</h1><p>Description</p>"

  suite "VM Literals":
    test "String literal":
      let source = "{{ 'hello world' }}"
      let data = initTable[string, VMValue]()
      let output = render_template(source, data)
      check output == "hello world"

    test "Number literals":
      let source = "Int: {{ 42 }} Float: {{ 3.14 }}"
      let data = initTable[string, VMValue]()
      let output = render_template(source, data)
      check output == "Int: 42 Float: 3.14"

    test "Boolean literals":
      let source = "True: {{ true }} False: {{ false }}"
      let data = initTable[string, VMValue]()
      let output = render_template(source, data)
      check output == "True: true False: false"

    test "Nil literal - actual":
      let source = "Nil: '{{ nil }}'"
      let data = initTable[string, VMValue]()
      let output = render_template(source, data)
      
      # The single quotes might be getting escaped
      # Let's check what we actually get
      echo "Nil output: '", output, "'"
      check "Nil: " in output

  suite "VM Filters":
    test "Upcase filter":
      let source = "{{ name | upcase }}"
      let data = {"name": vmString("hello")}.toTable
      let output = render_template(source, data)
      check output == "HELLO"

    test "Downcase filter":
      let source = "{{ name | downcase }}"
      let data = {"name": vmString("HELLO")}.toTable
      let output = render_template(source, data)
      check output == "hello"

    test "Size filter":
      let source = "{{ items | size }}"
      let data = {"items": to_vm_value(@[1, 2, 3, 4, 5])}.toTable
      let output = render_template(source, data)
      check output == "5"

    test "First filter":
      let source = "{{ items | first }}"
      let data = {"items": to_vm_value(@["a", "b", "c"])}.toTable
      let output = render_template(source, data)
      check output == "a"

    test "Last filter":
      let source = "{{ items | last }}"
      let data = {"items": to_vm_value(@["a", "b", "c"])}.toTable
      let output = render_template(source, data)
      check output == "c"

    test "Chained filters":
      let source = "{{ name | downcase | size }}"
      let data = {"name": vmString("HELLO")}.toTable
      let output = render_template(source, data)
      check output == "5"

  suite "VM Complex Templates":
    test "Blog post template":
      let source = """<article>
    <h1>{{ post.title }}</h1>
    <p>By {{ post.author }} on {{ post.date }}</p>
    
    {% if post.tags %}
      <ul>
      {% for tag in post.tags %}
        <li>{{ tag }}</li>
      {% endfor %}
      </ul>
    {% endif %}
    
    <div>{{ post.content }}</div>
  </article>"""
      
      let data = {
        "post": make_object(
          ("title", vmString("Hello World")),
          ("author", vmString("Alice")),
          ("date", vmString("2024-01-01")),
          ("tags", to_vm_value(@["nim", "templates", "liquid"])),
          ("content", vmString("This is the post content."))
        )
      }.toTable
      
      let output = render_template(source, data)
      check "Hello World" in output
      check "Alice" in output
      check "<li>nim</li>" in output
      check "<li>templates</li>" in output
      check "<li>liquid</li>" in output

    test "Shopping cart":
      let source = """{% assign total = 0 %}
  {% for item in cart %}
    {{ item.name }}: ${{ item.price }} x {{ item.quantity }}
  {% endfor %}
  Total items: {{ cart | size }}"""
      
      let data = {
        "cart": vmArray(@[
          make_object(
            ("name", vmString("Book")),
            ("price", vmFloat(19.99)),
            ("quantity", vmInt(2))
          ),
          make_object(
            ("name", vmString("Pen")),
            ("price", vmFloat(1.99)),
            ("quantity", vmInt(5))
          )
        ])
      }.toTable
      
      let output = render_template(source, data)
      check "Book: $19.99 x 2" in output
      check "Pen: $1.99 x 5" in output
      check "Total items: 2" in output

  suite "VM Edge Cases":
    test "Deeply nested properties":
      let source = "{{ a.b.c.d.e }}"
      let data = {
        "a": make_object(
          ("b", make_object(
            ("c", make_object(
              ("d", make_object(
                ("e", vmString("deep"))
              ))
            ))
          ))
        )
      }.toTable
      let output = render_template(source, data)
      check output == "deep"

    test "HTML escaping":
      let source = "{{ content }}"
      let data = {"content": vmString("<script>alert('xss')</script>")}.toTable
      
      # Create VM with HTML escaping enabled (not default in Liquid, but available)
      let sections = lex(source)
      let compiled = compile(sections, source)
      var vm = new_liquid_vm(compiled.bytecode, compiled.strings, compiled.constants, addr data)
      vm.escape_html = true
      let output = vm.execute()
      
      check "<script>" notin output
      check "&lt;script&gt;" in output

    test "Division by zero":
      let source = "{{ 10 / 0 }}"
      let data = initTable[string, VMValue]()
      let output = render_template(source, data)
      
      check output == ""

    test "Division by zero - float":
      let source = "{{ 10.5 / 0.0 }}"
      let data = initTable[string, VMValue]()
      let output = render_template(source, data)
      
      check output == "inf"

    test "Modulo by zero":
      let source = "{{ 10 % 0 }}"
      let data = initTable[string, VMValue]()
      let output = render_template(source, data)
      
      check output == ""

    test "Array index out of bounds - positive":
      let source = "{{ items[10] }}"
      let data = {
        "items": to_vm_value(@["a", "b", "c"])
      }.toTable
      let output = render_template(source, data)
      
      check output == ""

    test "Array index out of bounds - negative":
      let source = "{{ items[-1] }}"
      let data = {
        "items": to_vm_value(@["a", "b", "c"])
      }.toTable
      let output = render_template(source, data)
      
      check output == "c"

    test "Array index with non-integer":
      let source = "{{ items['hello'] }}"
      let data = {
        "items": to_vm_value(@["a", "b", "c"])
      }.toTable
      let output = render_template(source, data)
      
      check output == ""

    test "Null property access":
      let source = "{{ nothing.property }}"
      let data = initTable[string, VMValue]()
      let output = render_template(source, data)
      
      check output == ""

    test "Deep property chain with null":
      let source = "{{ a.b.c.d.e.f.g }}"
      let data = {
        "a": make_object(
          ("b", vmNull())
        )
      }.toTable
      let output = render_template(source, data)
      
      check output == ""

    test "Type coercion edge cases":
      let source1 = "{{ true + 1 }}"
      let output1 = render_template(source1, initTable[string, VMValue]())
      
      check output1 == ""

    test "String coercion 1":
      let source = "{{ '5' + 5 }}"
      let output = render_template(source, initTable[string, VMValue]())

      check output == "55"

    test "String coercion 1":
      let source = "{{ 5 + '5' }}"
      let output = render_template(source, initTable[string, VMValue]())

      check output == "55"

    test "Empty array/object operations":
      let source = """
  {{ empty_array | first }}
  {{ empty_array | last }}
  {{ empty_object.anything }}
  """
      let data = {
        "empty_array": vmArray(@[]),
        "empty_object": vmObject(initOrderedTable[string, VMValue]())
      }.toTable
      let output = render_template(source, data)
      
      check output.strip() == ""

    test "Infinite loop protection":
      # This is a stress test - the VM should handle very long loops
      # In production, you might want a max iteration limit
      let source = "{% for i in items %}{{ i }}{% endfor %}"
      
      # Create a very large array
      var big_array: seq[VMValue] = @[]
      for i in 0..1000:
        big_array.add(vmInt(i))
      
      let data = {
        "items": vmArray(big_array)
      }.toTable
      
      let output = render_template(source, data)
      
      # Should complete without hanging
      check output.len > 0
      check "500" in output  # Middle element should be there

  suite "Logical Operators":
    test "Simple and - both true":
      let source = "{% if true and true %}yes{% endif %}"
      let output = render_template(source, initTable[string, VMValue]())
      check output == "yes"

    test "Simple and - one false":
      let source = "{% if true and false %}yes{% endif %}"
      let output = render_template(source, initTable[string, VMValue]())
      check output == ""

    test "Simple or - one true":
      let source = "{% if false or true %}yes{% endif %}"
      let output = render_template(source, initTable[string, VMValue]())
      check output == "yes"

    test "Simple or - both false":
      let source = "{% if false or false %}yes{% endif %}"
      let output = render_template(source, initTable[string, VMValue]())
      check output == ""

    test "Not operator":
      let source = "{% if not false %}yes{% endif %}"
      let output = render_template(source, initTable[string, VMValue]())
      check output == "yes"

    test "Right-associative and/or":
      # true and false and false or true
      # Right-associative: true and (false and (false or true))
      # = true and (false and true) = true and false = false
      let source = "{% if true and false and false or true %}yes{% endif %}"
      let output = render_template(source, initTable[string, VMValue]())
      check output == ""

    test "And with variables":
      let source = "{% if a and b %}yes{% else %}no{% endif %}"
      let data = {"a": VMValue(kind: vmBool, boolVal: true), "b": VMValue(kind: vmBool, boolVal: false)}.toTable
      let output = render_template(source, data)
      check output == "no"

  suite "For Loop Limit/Offset":
    test "For with limit":
      let source = "{% for i in items limit: 2 %}{{ i }} {% endfor %}"
      let data = {"items": vmArray(@[vmInt(1), vmInt(2), vmInt(3), vmInt(4)])}.toTable
      let output = render_template(source, data)
      check output == "1 2 "

    test "For with offset":
      let source = "{% for i in items offset: 2 %}{{ i }} {% endfor %}"
      let data = {"items": vmArray(@[vmInt(1), vmInt(2), vmInt(3), vmInt(4)])}.toTable
      let output = render_template(source, data)
      check output == "3 4 "

    test "For with limit and offset":
      let source = "{% for i in items limit: 2 offset: 1 %}{{ i }} {% endfor %}"
      let data = {"items": vmArray(@[vmInt(1), vmInt(2), vmInt(3), vmInt(4)])}.toTable
      let output = render_template(source, data)
      check output == "2 3 "

    test "Limit with non-numeric type raises":
      let source = "{% for i in (1..4) limit: foo %}{{ i }} {% endfor %}"
      let data = {"foo": vmArray(@[vmInt(1), vmInt(2)])}.toTable
      expect CatchableError:
        discard render_template(source, data)

    test "Offset with non-numeric type raises":
      let source = "{% for i in (1..4) offset: foo %}{{ i }} {% endfor %}"
      let data = {"foo": vmArray(@[vmInt(1), vmInt(2)])}.toTable
      expect CatchableError:
        discard render_template(source, data)

  suite "Arithmetic Operators":
    test "Subtract integers":
      let source = "{% assign a = 5 %}{% assign b = 3 %}{% assign c = a | minus: b %}{{ c }}"
      let data = initTable[string, VMValue]()
      check render_template(source, data) == "2"

    test "Subtract null treated as zero":
      let source = "{% decrement x %}{% decrement x %}"
      let data = initTable[string, VMValue]()
      check render_template(source, data) == "-1-2"

    test "Increment from null":
      let source = "{% increment x %}{% increment x %}"
      let data = initTable[string, VMValue]()
      check render_template(source, data) == "01"

    test "Unless tag - condition false":
      let source = "{% unless false %}yes{% endunless %}"
      let data = initTable[string, VMValue]()
      check render_template(source, data) == "yes"

    test "Unless tag - condition true":
      let source = "{% unless true %}yes{% endunless %}"
      let data = initTable[string, VMValue]()
      check render_template(source, data) == ""

    test "Unless tag with else":
      let source = "{% unless true %}yes{% else %}no{% endunless %}"
      let data = initTable[string, VMValue]()
      check render_template(source, data) == "no"

  suite "Forloop Helper":
    test "Forloop index and index0":
      let source = "{% for i in items %}{{ forloop.index }}-{{ forloop.index0 }} {% endfor %}"
      let data = {"items": vmArray(@[vmInt(1), vmInt(2), vmInt(3)])}.toTable
      check render_template(source, data) == "1-0 2-1 3-2 "

    test "Forloop first and last":
      let source = "{% for i in items %}{{ forloop.first }}-{{ forloop.last }} {% endfor %}"
      let data = {"items": vmArray(@[vmInt(1), vmInt(2), vmInt(3)])}.toTable
      check render_template(source, data) == "true-false false-false false-true "

    test "Forloop length":
      let source = "{% for i in items %}{{ forloop.length }} {% endfor %}"
      let data = {"items": vmArray(@[vmInt(1), vmInt(2), vmInt(3)])}.toTable
      check render_template(source, data) == "3 3 3 "

    test "Forloop rindex and rindex0":
      let source = "{% for i in items %}{{ forloop.rindex }}-{{ forloop.rindex0 }} {% endfor %}"
      let data = {"items": vmArray(@[vmInt(1), vmInt(2), vmInt(3)])}.toTable
      check render_template(source, data) == "3-2 2-1 1-0 "

    test "Forloop goes out of scope after loop":
      let source = "{% for i in items %}{{ forloop.length }} {% endfor %}{{ forloop.length }}"
      let data = {"items": vmArray(@[vmInt(1), vmInt(2)])}.toTable
      check render_template(source, data) == "2 2 "

    test "Nested forloop parentloop":
      let source = "{% for i in (1..2) %}{% for j in (1..2) %}{{ forloop.parentloop.index }}-{{ forloop.index }} {% endfor %}{% endfor %}"
      let data = initTable[string, VMValue]()
      check render_template(source, data) == "1-1 1-2 2-1 2-2 "

    test "Parentloop undefined for top-level loop":
      let source = "{% for i in (1..2) %}{{ forloop.parentloop.index }}{% endfor %}"
      let data = initTable[string, VMValue]()
      check render_template(source, data) == ""

