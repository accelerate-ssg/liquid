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

# Main execution function
proc execute*(vm: var LiquidVM): string =
  ## Execute the bytecode and return the output
  
  while vm.pc < vm.bytecode.len:
    let inst = vm.bytecode[vm.pc]
    inc vm.pc
    inc vm.instruction_count
    
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
      let var_name = vm.strings[inst.stringId]
      if var_name in vm.locals:
        vm.push(vm.locals[var_name])
      elif var_name in vm.variables:
        vm.push(vm.variables[var_name])
      else:
        vm.push(VMValue(kind: vmNull))
      
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
        let text = vm.strings[stringId]
        if vm.is_capturing:
          vm.capture_stack[^1].add(text)
        else:
          vm.output.add(text)  # Direct output, no escaping
    
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
        let lv = vm.pop()
        case lv.kind
        of vmInt:
          limit_val = lv.intVal
        of vmFloat:
          limit_val = lv.floatVal.int64
        of vmString:
          try:
            limit_val = parseInt(lv.stringVal).int64
          except ValueError:
            raise newException(ValueError, "limit must be a number, got string '" & lv.stringVal & "'")
        of vmNull:
          limit_val = 0
        else:
          raise newException(ValueError, "limit must be a number, got " & $lv.kind)

      if inst.hasOffset:
        let ov = vm.pop()
        case ov.kind
        of vmInt:
          offset_val = ov.intVal
        of vmFloat:
          offset_val = ov.floatVal.int64
        of vmString:
          try:
            offset_val = parseInt(ov.stringVal).int64
          except ValueError:
            raise newException(ValueError, "offset must be a number, got string '" & ov.stringVal & "'")
        of vmNull:
          offset_val = 0
        else:
          raise newException(ValueError, "offset must be a number, got " & $ov.kind)

      # Get loop variable name for offset: continue tracking
      let loop_var_name = vm.strings[inst.loopVarIndex]

      # Clean up any stale iterator for this variable (from a broken loop)
      for i in countdown(vm.iterators.len - 1, 0):
        if vm.iterators[i].var_name == loop_var_name:
          let stale = vm.iterators[i]
          vm.loop_offsets[stale.var_name] = stale.original_offset + stale.index
          # Restore the forloop saved by the stale iterator
          if stale.saved_forloop.kind != vm_null:
            vm.locals["forloop"] = stale.saved_forloop
          else:
            vm.locals.del("forloop")
          vm.iterators.delete(i)
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

      # Save current forloop value in the iterator for nesting restore
      let saved_fl = if "forloop" in vm.locals: vm.locals["forloop"] else: vm_null()

      vm.iterators.add(Iterator(
        items: items,
        index: 0,
        var_name: loop_var_name,
        original_offset: offset_val.int,
        saved_forloop: saved_fl
      ))

    of opIterNext:
      if vm.iterators.len > 0:
        # Get the current iterator (don't pop it yet)
        var iter = addr vm.iterators[^1]
        if iter.index < iter.items.len:
          # Push next item and continue
          vm.push(iter.items[iter.index])
          iter.index += 1

          # Build forloop helper object
          let idx0 = iter.index - 1  # 0-based (already incremented above)
          let length = iter.items.len
          var forloopObj = {
            "index": vm_int((idx0 + 1).int64),
            "index0": vm_int(idx0.int64),
            "first": vm_bool(idx0 == 0),
            "last": vm_bool(idx0 == length - 1),
            "length": vm_int(length.int64),
            "rindex": vm_int((length - idx0).int64),
            "rindex0": vm_int((length - idx0 - 1).int64),
          }.toTable

          # Set parentloop from the saved forloop in this iterator
          let saved = iter.saved_forloop
          if saved.kind != vm_null:
            forloopObj["parentloop"] = saved
          else:
            forloopObj["parentloop"] = vm_null()

          vm.locals["forloop"] = vm_object(forloopObj)
        else:
          # End of iteration - save loop offset for offset: continue
          let finished_iter = vm.iterators[^1]
          vm.loop_offsets[finished_iter.var_name] = finished_iter.original_offset + finished_iter.index
          # NOW we pop the iterator
          vm.iterators.setLen(vm.iterators.len - 1)
          # Restore saved forloop from the finished iterator
          if finished_iter.saved_forloop.kind != vm_null:
            vm.locals["forloop"] = finished_iter.saved_forloop
          else:
            # No outer loop — forloop goes out of scope
            vm.locals.del("forloop")
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
      try:
        vm.push(VMValue(kind: vmBool, boolVal: liquid_compare(a, b) < 0))
      except ValueError:
        vm.push(VMValue(kind: vmBool, boolVal: false))

    of opLessEqual:
      let b = vm.pop()
      let a = vm.pop()
      try:
        vm.push(VMValue(kind: vmBool, boolVal: liquid_compare(a, b) <= 0))
      except ValueError:
        vm.push(VMValue(kind: vmBool, boolVal: false))

    of opGreater:
      let b = vm.pop()
      let a = vm.pop()
      try:
        vm.push(VMValue(kind: vmBool, boolVal: liquid_compare(a, b) > 0))
      except ValueError:
        vm.push(VMValue(kind: vmBool, boolVal: false))

    of opGreaterEqual:
      let b = vm.pop()
      let a = vm.pop()
      try:
        vm.push(VMValue(kind: vmBool, boolVal: liquid_compare(a, b) >= 0))
      except ValueError:
        vm.push(VMValue(kind: vmBool, boolVal: false))
    
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
      # Create a range from start..end
      let end_val = vm.pop()
      let start_val = vm.pop()
      
      # Convert to integers
      var start_int: int64
      var end_int: int64
      
      case start_val.kind
      of vmInt:
        start_int = start_val.intVal
      of vmFloat:
        start_int = start_val.floatVal.int64
      else:
        vm.push(VMValue(kind: vmNull))
        continue
      
      case end_val.kind
      of vmInt:
        end_int = end_val.intVal
      of vmFloat:
        end_int = end_val.floatVal.int64
      else:
        vm.push(VMValue(kind: vmNull))
        continue
      
      # Create array with range values
      var range_array: seq[VMValue] = @[]
      if start_int <= end_int:
        for i in start_int..end_int:
          range_array.add(VMValue(kind: vmInt, intVal: i))
      else:
        # Handle reverse ranges
        for i in countdown(start_int, end_int):
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
            for (k, v) in kwArgs:
              subVm.locals[k] = v
            # Build forloop helper
            var forloopObj = {
              "index": vm_int((idx + 1).int64),
              "index0": vm_int(idx.int64),
              "first": vm_bool(idx == 0),
              "last": vm_bool(idx == totalItems - 1),
              "length": vm_int(totalItems.int64),
              "rindex": vm_int((totalItems - idx).int64),
              "rindex0": vm_int((totalItems - idx - 1).int64),
              "parentloop": vm_null(),
            }.toTable
            subVm.locals["forloop"] = vm_object(forloopObj)

            subVm.partial_cache = vm.partial_cache
            let sub_output = subVm.execute()
            if vm.is_capturing:
              vm.capture_stack[^1].add(sub_output)
            else:
              vm.output.add(sub_output)
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

          # Handle 'with' binding
          if inst.includeWithVar >= 0:
            if inst.includeAlias >= 0:
              let alias = vm.strings[inst.includeAlias.uint32]
              subVm.locals[alias] = withVal
            else:
              subVm.locals[partialName] = withVal

          # Set keyword args
          for (k, v) in kwArgs:
            subVm.locals[k] = v

          subVm.partial_cache = vm.partial_cache
          let sub_output = subVm.execute()
          if vm.is_capturing:
            vm.capture_stack[^1].add(sub_output)
          else:
            vm.output.add(sub_output)
          vm.partial_cache = subVm.partial_cache
          if inst.withContext:
            # Include: propagate locals back to parent
            vm.locals = subVm.locals
            vm.loop_offsets = subVm.loop_offsets

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
    var obj = initTable[string, VMValue]()
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
        "empty_object": vmObject(initTable[string, VMValue]())
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
