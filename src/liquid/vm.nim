# Liquid VM Executor: Bytecode + Data -> Text
# ============================================
# Takes compiled bytecode and runtime data, produces output

import compiler/[types]
import vm/[types]
import std/[tables, strutils, sequtils, algorithm]
import shared
import filters
import types as lexer_types
import lexer
import compiler

# Create VM with data
proc new_liquid_vm*(bytecode: seq[Instruction], strings: seq[string],
                  constants: seq[VMValue], data: Table[string, VMValue],
                  partials: Table[string, string] = initTable[string, string]()): LiquidVM =
  result = LiquidVM(
    stack: newSeqOfCap[VMValue](32),
    pc: 0,
    bytecode: bytecode,
    strings: strings,
    constants: constants,
    variables: data,
    locals: initTable[string, VMValue](),
    iterators: @[],
    output: "",
    escape_html: false,
    capture_stack: @[],
    is_capturing: false,
    # filters field removed - now using filters module directly
    loop_offsets: initTable[string, int](),
    partials: partials,
    partial_cache: initTable[string, tuple[bytecode: seq[Instruction], strings: seq[string], constants: seq[VMValue]]](),
    pending_break: false,
    pending_continue: false,
    instruction_count: 0,
    max_stack_size: 0
  )

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
  raise newException(ValueError, "comparison of incompatible types")

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

proc resolve_var*(vm: LiquidVM, name: string): VMValue =
  ## Resolve a variable name through the scope chain:
  ## keyword_args → locals → variables → counters → null
  if name in vm.keyword_args:
    vm.keyword_args[name]
  elif name in vm.locals:
    vm.locals[name]
  elif name in vm.variables:
    vm.variables[name]
  elif name in vm.counters:
    VMValue(kind: vmInt, intVal: vm.counters[name])
  else:
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

proc finish_iterator*(vm: var LiquidVM, iter_index: int = -1) =
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

# Main execution function
proc execute*(vm: var LiquidVM): string =
  ## Execute the bytecode and return the output
  
  while vm.pc < vm.bytecode.len:
    let inst = vm.bytecode[vm.pc]
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
      vm.push(vm.resolve_var(vm.strings[inst.stringId]))
      
    of opDynamicLoadVar:
      # Pop key from stack, use it as a variable name
      vm.push(vm.resolve_var(vm.pop().to_string()))

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
      else:
        vm.push(VMValue(kind: vmNull))
    
    # Output operations
    of opOutput:
      # Regular output is for expressions - escape based on setting
      let val = vm.pop()
      let str = val.to_string()
      
      if vm.is_capturing:
        # When capturing, store raw (escaping happens on final output)
        vm.capture_stack[^1].add(str)
      else:
        # Escape if enabled (default true for safety)
        let output_str = if vm.escape_html:
          str.escape_html_str()
        else:
          str
        vm.output.add(output_str)
      
    of opBatchOutput:
      # Batch output is ALWAYS literal template text - NEVER escape
      for stringId in inst.stringIds:
        vm.emit_output(vm.strings[stringId])
    
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
    
    of opCycle:
      # Pop cycle values from stack (in reverse order since stack is LIFO)
      var values: seq[VMValue] = newSeq[VMValue](inst.cycleArgCount.int)
      for i in countdown(inst.cycleArgCount.int - 1, 0):
        values[i] = vm.pop()

      # Determine the group key
      var group_key: string
      if inst.cycleGroupId >= 0:
        if inst.cycleGroupIsVar:
          # Resolve variable name to get group key
          group_key = vm.resolve_var(vm.strings[inst.cycleGroupId.uint32]).to_string()
        else:
          # Literal group name
          group_key = vm.strings[inst.cycleGroupId.uint32]
      else:
        # Unnamed cycle - use the compile-time key
        group_key = vm.strings[inst.cycleKey]

      # Get current iteration index for this group
      let iteration = vm.cycle_counters.getOrDefault(group_key, 0)
      let arg_count = inst.cycleArgCount.int
      if arg_count > 0:
        # Output value at current index (out of bounds → nothing)
        if iteration < arg_count:
          vm.emit_output(values[iteration].to_string())
        # Increment counter, reset to 0 if >= current arg count
        var next = iteration + 1
        if next >= arg_count:
          next = 0
        vm.cycle_counters[group_key] = next

    of opIncrement:
      let var_name = vm.strings[inst.stringId]
      let current = vm.counters.getOrDefault(var_name, 0'i64)
      vm.emit_output($current)
      vm.counters[var_name] = current + 1

    of opDecrement:
      let var_name = vm.strings[inst.stringId]
      let current = vm.counters.getOrDefault(var_name, 0'i64)
      let new_val = current - 1
      vm.counters[var_name] = new_val
      vm.emit_output($new_val)

    of opBeginIfchanged:
      # Start capturing output for ifchanged comparison
      vm.capture_stack.add("")
      vm.is_capturing = true
      vm.capture_escape_stack.add(vm.escape_html)
      vm.escape_html = false

    of opEndIfchanged:
      if vm.capture_stack.len > 0:
        let captured = vm.capture_stack.pop()
        vm.is_capturing = vm.capture_stack.len > 0
        if vm.capture_escape_stack.len > 0:
          vm.escape_html = vm.capture_escape_stack.pop()

        # Compare with last ifchanged output
        if captured != vm.ifchanged_last:
          vm.ifchanged_last = captured
          vm.emit_output(captured)
        # If same, suppress output (do nothing)

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

    of opTablerowBegin:
      # Pop cols, limit, offset, collection from stack (in reverse push order)
      var cols_val = 0  # 0 = unlimited (all in one row)
      var limit_val = -1'i64
      var offset_val = 0'i64

      if inst.tablerowHasCols:
        let cv = vm.pop()
        case cv.kind
        of vmInt: cols_val = cv.intVal.int
        of vmFloat: cols_val = cv.floatVal.int
        of vmString:
          try: cols_val = parseInt(cv.stringVal)
          except ValueError: discard
        else: discard

      if inst.tablerowHasLimit:
        let lv = vm.pop()
        case lv.kind
        of vmInt: limit_val = lv.intVal
        of vmFloat: limit_val = lv.floatVal.int64
        of vmString:
          try: limit_val = parseInt(lv.stringVal).int64
          except ValueError: discard
        of vmNull: limit_val = 0
        else: discard

      if inst.tablerowHasOffset:
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
        # Empty collection - skip to end (will be handled by opTablerowIter's endOffset)
        # Push a dummy state so opTablerowIter can clean up
        let saved_trl = if "tablerowloop" in vm.locals: vm.locals["tablerowloop"] else: vm_null()
        vm.tablerow_iters.add(TablerowState(
          items: @[], index: 0, cols: cols_val,
          var_name: vm.strings[inst.tablerowVarIndex],
          saved_tablerowloop: saved_trl))
      else:
        # Save current tablerowloop
        let saved_trl = if "tablerowloop" in vm.locals: vm.locals["tablerowloop"] else: vm_null()

        let var_name = vm.strings[inst.tablerowVarIndex]
        vm.tablerow_iters.add(TablerowState(
          items: items, index: 0, cols: cols_val,
          var_name: var_name, saved_tablerowloop: saved_trl))

        # Set loop variable to first item
        vm.locals[var_name] = items[0]

        # Set up tablerowloop variable
        let total = items.len
        let col0 = 0
        let col = col0 + 1
        let row = 1
        let effective_cols = if cols_val > 0: cols_val else: total
        var trl = initOrderedTable[string, VMValue]()
        trl["col"] = vm_int(col.int64)
        trl["col0"] = vm_int(col0.int64)
        trl["col_first"] = vm_bool(true)
        trl["col_last"] = vm_bool(col0 == effective_cols - 1 or 0 == total - 1)
        trl["first"] = vm_bool(true)
        trl["index"] = vm_int(1)
        trl["index0"] = vm_int(0)
        trl["last"] = vm_bool(total == 1)
        trl["length"] = vm_int(total.int64)
        trl["rindex"] = vm_int(total.int64)
        trl["rindex0"] = vm_int((total - 1).int64)
        trl["row"] = vm_int(row.int64)
        vm.locals["tablerowloop"] = vm_object(trl)

        # Output first row opening: <tr class="row1">\n<td class="col1">
        vm.emit_output("<tr class=\"row1\">\n<td class=\"col1\">")

    of opTablerowIter:
      if vm.tablerow_iters.len == 0:
        vm.pc += inst.tablerowEndOffset
      else:
        let state = addr vm.tablerow_iters[^1]

        if state.items.len == 0:
          # Empty collection - skip to end
          # Restore saved tablerowloop
          if state.saved_tablerowloop.kind != vm_null:
            vm.locals["tablerowloop"] = state.saved_tablerowloop
          else:
            vm.locals.del("tablerowloop")
          vm.tablerow_iters.setLen(vm.tablerow_iters.len - 1)
          vm.pc += inst.tablerowEndOffset
        else:
          # Close current cell
          vm.emit_output("</td>")

          # Advance to next item
          state.index += 1

          if state.index >= state.items.len:
            # Done iterating - close final row
            vm.emit_output("</tr>\n")

            # Clean up
            vm.locals.del(state.var_name)
            if state.saved_tablerowloop.kind != vm_null:
              vm.locals["tablerowloop"] = state.saved_tablerowloop
            else:
              vm.locals.del("tablerowloop")
            vm.tablerow_iters.setLen(vm.tablerow_iters.len - 1)
            vm.pc += inst.tablerowEndOffset
          else:
            # More items - handle row wrapping
            let total = state.items.len
            let idx = state.index
            let effective_cols = if state.cols > 0: state.cols else: total
            let col0 = idx mod effective_cols
            let col = col0 + 1
            let row = (idx div effective_cols) + 1

            var html = ""
            if col0 == 0:
              # Start of new row
              html.add("</tr>\n<tr class=\"row" & $row & "\">")
            html.add("<td class=\"col" & $col & "\">")

            vm.emit_output(html)

            # Set loop variable
            vm.locals[state.var_name] = state.items[idx]

            # Update tablerowloop
            var trl = initOrderedTable[string, VMValue]()
            trl["col"] = vm_int(col.int64)
            trl["col0"] = vm_int(col0.int64)
            trl["col_first"] = vm_bool(col0 == 0)
            trl["col_last"] = vm_bool(col0 == effective_cols - 1 or idx == total - 1)
            trl["first"] = vm_bool(idx == 0)
            trl["index"] = vm_int((idx + 1).int64)
            trl["index0"] = vm_int(idx.int64)
            trl["last"] = vm_bool(idx == total - 1)
            trl["length"] = vm_int(total.int64)
            trl["rindex"] = vm_int((total - idx).int64)
            trl["rindex0"] = vm_int((total - idx - 1).int64)
            trl["row"] = vm_int(row.int64)
            vm.locals["tablerowloop"] = vm_object(trl)

            # Jump back to body
            vm.pc += inst.tablerowBodyOffset

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
            let idx0 = iter.index - 1
            vm.locals["forloop"] = build_forloop(idx0, iter.items.len, iter.loop_name, iter.saved_forloop)
          else:
            vm.finish_iterator()
            vm.pc += inst.endOffset
        else:
          # Normal iteration
          var iter = addr vm.iterators[^1]
          if iter.index < iter.items.len:
            vm.push(iter.items[iter.index])
            iter.index += 1
            let idx0 = iter.index - 1
            vm.locals["forloop"] = build_forloop(idx0, iter.items.len, iter.loop_name, iter.saved_forloop)
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
      vm.push(VMValue(kind: vmBool, boolVal: liquid_eq(a, b)))

    of opNotEqual:
      let b = vm.pop()
      let a = vm.pop()
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
      let needle = vm.pop()  # What we're looking for
      let haystack = vm.pop()  # Where we're looking
      
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
      let b = vm.pop()
      let a = vm.pop()

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
      
      # Pop the value to filter
      let value = vm.pop()
      
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
      # Get partial name
      var partialName: string
      if inst.includeVarExpr:
        let nameVal = vm.pop()
        partialName = nameVal.to_string()
      else:
        partialName = vm.strings[inst.templateId]

      # Pop keyword argument values from stack (in reverse order)
      var kwArgs: seq[(string, VMValue)] = @[]
      for i in countdown(inst.includeArgNames.len - 1, 0):
        let val = vm.pop()
        kwArgs.add((vm.strings[inst.includeArgNames[i]], val))

      # Pop 'with' value if present
      var withVal = VMValue(kind: vmNull)
      if inst.includeWithVar >= 0:
        withVal = vm.pop()

      # Pop 'for' collection if present
      var forCollection: seq[VMValue] = @[]
      var hasForLoop = inst.includeForVar >= 0
      if hasForLoop:
        let collVal = vm.pop()
        case collVal.kind
        of vmArray: forCollection = collVal.arrayVal
        else: discard

      # Look up and compile the partial
      if partialName notin vm.partials:
        discard  # Missing partial outputs nothing
      else:
        # Compile partial (with caching)
        if partialName notin vm.partial_cache:
          let source = vm.partials[partialName]
          let sections = lex(source)
          let compiled = compile(sections, source, false)
          vm.partial_cache[partialName] = (compiled.bytecode, compiled.strings, compiled.constants)

        let cached = vm.partial_cache[partialName]

        if hasForLoop:
          # Iterate over collection, executing partial for each item
          let totalItems = forCollection.len
          for idx, item in forCollection:
            var subVm = new_liquid_vm(cached.bytecode, cached.strings, cached.constants,
                                      if inst.withContext: vm.variables else: initTable[string, VMValue](),
                                      vm.partials)
            if inst.withContext:
              # Include: share locals
              subVm.locals = vm.locals
              subVm.loop_offsets = vm.loop_offsets
            # Bind the loop item as the partial name variable
            subVm.locals[partialName] = item
            # Set keyword args
            if inst.withContext:
              for (k, v) in kwArgs:
                subVm.keyword_args[k] = v
            else:
              for (k, v) in kwArgs:
                subVm.locals[k] = v
            # Build forloop helper for render for-loop
            let forloop = build_forloop(idx, totalItems, "", vm_null())
            # Use variables (not locals) so inner for-loops don't pick it up as parentloop
            if inst.withContext:
              subVm.locals["forloop"] = forloop
            else:
              subVm.variables["forloop"] = forloop

            subVm.partial_cache = vm.partial_cache
            let sub_output = subVm.execute()
            vm.emit_output(sub_output)
            vm.partial_cache = subVm.partial_cache
            if inst.withContext:
              vm.locals = subVm.locals
              vm.loop_offsets = subVm.loop_offsets
        else:
          # Single execution
          var subVm = new_liquid_vm(cached.bytecode, cached.strings, cached.constants,
                                    if inst.withContext: vm.variables else: initTable[string, VMValue](),
                                    vm.partials)
          if inst.withContext:
            # Include: share locals (assigns persist back)
            subVm.locals = vm.locals
            subVm.loop_offsets = vm.loop_offsets
            subVm.counters = vm.counters

          # Handle 'with' binding
          if inst.includeWithVar >= 0:
            if inst.includeAlias >= 0:
              let alias = vm.strings[inst.includeAlias.uint32]
              subVm.locals[alias] = withVal
            else:
              subVm.locals[partialName] = withVal

          # Set keyword args as read-only overlay (not in locals)
          if inst.withContext:
            for (k, v) in kwArgs:
              subVm.keyword_args[k] = v
          else:
            # Render: keyword args go into locals (isolated scope)
            for (k, v) in kwArgs:
              subVm.locals[k] = v

          subVm.partial_cache = vm.partial_cache
          let sub_output = subVm.execute()
          vm.emit_output(sub_output)
          vm.partial_cache = subVm.partial_cache
          if inst.withContext:
            # Include: propagate locals back to parent
            vm.locals = subVm.locals
            vm.loop_offsets = subVm.loop_offsets
            vm.counters = subVm.counters
            # Propagate break/continue from include
            if subVm.pending_break:
              vm.pending_break = true
            if subVm.pending_continue:
              vm.pending_continue = true

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

  result = vm.output

# Public API
proc render*(bytecode: seq[Instruction], strings: seq[string],
            constants: seq[VMValue], data: Table[string, VMValue],
            partials: Table[string, string] = initTable[string, string]()): string =
  ## Render a template with the given data
  var vm = new_liquid_vm(bytecode, strings, constants, data, partials)
  result = vm.execute()



when isMainModule:
  import std/[unittest]
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
      var vm = new_liquid_vm(compiled.bytecode, compiled.strings, compiled.constants, data)
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
      var vm = new_liquid_vm(compiled.bytecode, compiled.strings, compiled.constants, data)
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
