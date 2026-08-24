# Liquid runtime tag handlers
# ===========================
# Runtime implementations for Liquid tags that execute via opCallTag
# dispatch (increment, decrement, cycle, ifchanged, tablerow).
# Registered on a VM with register_liquid_runtime().

import std/[tables, strutils]

import ../../bytecode
import ../../vm_types
import ../../values
import ../../vm

proc tag_increment(vm: var VM, inst: Instruction) =
  ## {% increment var %} - output current counter value, then increment
  let var_name = vm.strings[inst.tagData[0]]
  let current = vm.counters.getOrDefault(var_name, 0'i64)
  vm.emit_output($current)
  vm.counters[var_name] = current + 1

proc tag_decrement(vm: var VM, inst: Instruction) =
  ## {% decrement var %} - decrement counter, then output
  let var_name = vm.strings[inst.tagData[0]]
  let current = vm.counters.getOrDefault(var_name, 0'i64)
  let new_val = current - 1
  vm.counters[var_name] = new_val
  vm.emit_output($new_val)

proc tag_cycle(vm: var VM, inst: Instruction) =
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
      group_key = vm.resolve_var(vm.strings[group_id.uint32]).to_string()
    else:
      group_key = vm.strings[group_id.uint32]
  else:
    group_key = vm.strings[cycle_key.uint32]

  # Get current iteration index for this group
  let iteration = vm.cycle_counters.getOrDefault(group_key, 0)
  if arg_count > 0:
    if iteration < arg_count:
      vm.emit_output(values[iteration].to_string())
    var next = iteration + 1
    if next >= arg_count:
      next = 0
    vm.cycle_counters[group_key] = next

proc tag_ifchanged_begin(vm: var VM, inst: Instruction) =
  ## {% ifchanged %} - start capturing output for comparison
  vm.capture_stack.add("")
  vm.is_capturing = true
  vm.capture_escape_stack.add(vm.escape_html)
  vm.escape_html = false

proc tag_ifchanged_end(vm: var VM, inst: Instruction) =
  ## End ifchanged block - compare captured output with previous
  if vm.capture_stack.len > 0:
    let captured = vm.capture_stack.pop()
    vm.is_capturing = vm.capture_stack.len > 0
    if vm.capture_escape_stack.len > 0:
      vm.escape_html = vm.capture_escape_stack.pop()
    if captured != vm.ifchanged_last:
      vm.ifchanged_last = captured
      vm.emit_output(captured)

proc tag_tablerow_begin(vm: var VM, inst: Instruction) =
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
  else: discard

  # Apply offset
  if offset_val > 0 and offset_val < items.len.int64:
    items = items[offset_val..^1]
  elif offset_val >= items.len.int64:
    items = @[]

  # Apply limit
  if limit_val >= 0 and limit_val < items.len.int64:
    items = items[0..<limit_val]

  # Cell metadata (tablerowloop) is built lazily by the first lookup —
  # resolve_var consults the active tablerow state directly.
  if items.len == 0:
    vm.tablerow_iters.add(TablerowState(
      items: @[], index: 0, cols: cols_val,
      var_name: vm.strings[var_index]))
  else:
    let var_name = vm.strings[var_index]
    vm.tablerow_iters.add(TablerowState(
      items: items, index: 0, cols: cols_val,
      var_name: var_name))
    vm.locals[var_name] = items[0]
    vm.emit_output("<tr class=\"row1\">\n<td class=\"col1\">")

proc tag_tablerow_iter(vm: var VM, inst: Instruction) =
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
      # Metadata is rebuilt lazily by the first tablerowloop lookup of
      # the new cell.
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

proc register_liquid_runtime*(vm: var VM) =
  ## Register all Liquid tag runtime handlers
  vm.tag_handlers["increment"] = tag_increment
  vm.tag_handlers["decrement"] = tag_decrement
  vm.tag_handlers["cycle"] = tag_cycle
  vm.tag_handlers["ifchanged_begin"] = tag_ifchanged_begin
  vm.tag_handlers["ifchanged_end"] = tag_ifchanged_end
  vm.tag_handlers["tablerow_begin"] = tag_tablerow_begin
  vm.tag_handlers["tablerow_iter"] = tag_tablerow_iter

proc register_liquid_tag_handlers*(vm: var VM) {.deprecated: "renamed to register_liquid_runtime".} =
  register_liquid_runtime(vm)
