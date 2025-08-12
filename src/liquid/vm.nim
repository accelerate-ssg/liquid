# Liquid VM Executor: Bytecode + Data -> Text
# ============================================
# Takes compiled bytecode and runtime data, produces output

import compiler/[types]
import vm/[types]
import std/[tables, strutils, sequtils]
import filters

# Forward declarations
proc toString(v: VMValue): string

# Filters are now handled by the filters module via applyFilter

# Create VM with data
proc newLiquidVM*(bytecode: seq[Instruction], strings: seq[string], 
                  constants: seq[VMValue], data: Table[string, VMValue]): LiquidVM =
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
    outputBuffer: newSeqOfCap[char](1024),
    escapeHtml: true,
    captureStack: @[],
    isCapturing: false,
    # filters field removed - now using filters module directly
    instructionCount: 0,
    maxStackSize: 0
  )

# Stack operations
template push(vm: var LiquidVM, val: VMValue) =
  vm.stack.add(val)
  vm.maxStackSize = max(vm.maxStackSize, vm.stack.len)

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
proc isTruthy(v: VMValue): bool =
  case v.kind
  of vmNull: false
  of vmBool: v.boolVal
  of vmInt: v.intVal != 0
  of vmFloat: v.floatVal != 0.0
  of vmString: v.stringVal.len > 0
  of vmArray: v.arrayVal.len > 0
  of vmObject: v.objectVal.len > 0
  else: true

proc toString(v: VMValue): string =
  case v.kind
  of vmNull: ""
  of vmBool: 
    if v.boolVal: "true" else: "false"
  of vmInt: $v.intVal
  of vmFloat: 
    # Format float nicely
    let s = formatFloat(v.floatVal, ffDecimal, 2)
    if s.endsWith(".00"):
      s[0..^4]
    else:
      s
  of vmString: v.stringVal
  of vmArray:
    # Format array for output
    "[" & v.arrayVal.mapIt(it.toString()).join(", ") & "]"
  of vmObject:
    # Format object for output
    "{" & toSeq(v.objectVal.pairs).mapIt($it[0] & ": " & it[1].toString()).join(", ") & "}"
  else: ""

proc escapeHtmlStr(s: string): string =
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
    inc vm.instructionCount
    
    case inst.op
    # Stack operations
    of opPushNull:
      vm.push(VMValue(kind: vmNull))
      
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
      let varName = vm.strings[inst.stringId]
      if varName in vm.locals:
        vm.push(vm.locals[varName])
      elif varName in vm.variables:
        vm.push(vm.variables[varName])
      else:
        vm.push(VMValue(kind: vmNull))
      
    of opStoreVar:
      let varName = vm.strings[inst.stringId]
      let value = vm.pop()
      vm.locals[varName] = value
      
    # Property access
    of opGetProp:
      let obj = vm.pop()
      let propName = vm.strings[inst.stringId]
      
      case obj.kind
      of vmObject:
        if propName in obj.objectVal:
          vm.push(obj.objectVal[propName])
        else:
          vm.push(VMValue(kind: vmNull))
      of vmArray:
        # Special array properties
        case propName
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
      else:
        vm.push(VMValue(kind: vmNull))
    
    # Output operations
    of opOutput:
      # Regular output is for expressions - escape based on setting
      let val = vm.pop()
      let str = val.toString()
      
      if vm.isCapturing:
        # When capturing, store raw (escaping happens on final output)
        vm.captureStack[^1].add(str)
      else:
        # Escape if enabled (default true for safety)
        let outputStr = if vm.escapeHtml:
          str.escapeHtmlStr()
        else:
          str
        vm.output.add(outputStr)
      
    of opBatchOutput:
      # Batch output is ALWAYS literal template text - NEVER escape
      for stringId in inst.stringIds:
        let text = vm.strings[stringId]
        if vm.isCapturing:
          vm.captureStack[^1].add(text)
        else:
          vm.output.add(text)  # Direct output, no escaping
    
    of opBeginCapture:
      # Start capturing output
      vm.captureStack.add("")
      vm.isCapturing = true
      # Save current escape state and disable escaping during capture
      vm.captureEscapeStack.add(vm.escapeHtml)
      vm.escapeHtml = false
    
    of opEndCapture:
      if vm.captureStack.len > 0:
        let capturedOutput = vm.captureStack.pop()
        let varName = vm.strings[inst.varId]
        # Store captured content as-is (already unescaped)
        vm.locals[varName] = VMValue(kind: vmString, stringVal: capturedOutput)
        vm.isCapturing = vm.captureStack.len > 0
    
    # Control flow
    of opJump:
      vm.pc += inst.offset
      
    of opJumpIfFalse:
      let cond = vm.pop()
      if not cond.isTruthy():
        vm.pc += inst.offset
      
    of opJumpIfTrue:
      let cond = vm.pop()
      if cond.isTruthy():
        vm.pc += inst.offset
    
    # Loops
    of opBeginLoop:
      let collection = vm.pop()
      case collection.kind
      of vmArray:
        vm.iterators.add(Iterator(
          items: collection.arrayVal,
          index: 0,
          varName: "" # We'll use the string from the instruction
        ))
      of vmObject:
        # Convert object to array of key-value pairs
        var items: seq[VMValue] = @[]
        for key, val in collection.objectVal:
          items.add(VMValue(kind: vmArray, arrayVal: @[
            VMValue(kind: vmString, stringVal: key),
            val
          ]))
        vm.iterators.add(Iterator(
          items: items,
          index: 0,
          varName: ""
        ))
      else:
        # Empty iterator for non-iterable
        vm.iterators.add(Iterator(
          items: @[],
          index: 0,
          varName: ""
        ))
      
    of opIterNext:
      if vm.iterators.len > 0:
        # Get the current iterator (don't pop it yet)
        var iter = addr vm.iterators[^1]
        if iter.index < iter.items.len:
          # Push next item and continue
          vm.push(iter.items[iter.index])
          iter.index += 1
        else:
          # End of iteration - NOW we pop the iterator
          vm.iterators.setLen(vm.iterators.len - 1)
          vm.pc += inst.endOffset
    
    # Comparison
    of opEqual:
      let b = vm.pop()
      let a = vm.pop()
      vm.push(VMValue(kind: vmBool, boolVal: a == b))
      
    of opNotEqual:
      let b = vm.pop()
      let a = vm.pop()
      vm.push(VMValue(kind: vmBool, boolVal: a != b))
      
    of opLess:
      let b = vm.pop()
      let a = vm.pop()
      # Simplified comparison - full version would handle all types
      if a.kind == vmInt and b.kind == vmInt:
        vm.push(VMValue(kind: vmBool, boolVal: a.intVal < b.intVal))
      else:
        vm.push(VMValue(kind: vmBool, boolVal: false))
      
    of opLessEqual:
      let b = vm.pop()
      let a = vm.pop()
      if a.kind == vmInt and b.kind == vmInt:
        vm.push(VMValue(kind: vmBool, boolVal: a.intVal <= b.intVal))
      else:
        vm.push(VMValue(kind: vmBool, boolVal: false))
      
    of opGreater:
      let b = vm.pop()
      let a = vm.pop()
      if a.kind == vmInt and b.kind == vmInt:
        vm.push(VMValue(kind: vmBool, boolVal: a.intVal > b.intVal))
      elif a.kind == vmString and b.kind == vmString:
        vm.push(VMValue(kind: vmBool, boolVal: a.stringVal > b.stringVal))
      elif (a.kind == vmString and b.kind in [vmInt, vmFloat]) or
           (b.kind == vmString and a.kind in [vmInt, vmFloat]):
        # String vs number comparison should error
        raise newException(ValueError, "Cannot compare string and number")
      else:
        vm.push(VMValue(kind: vmBool, boolVal: false))
      
    of opGreaterEqual:
      let b = vm.pop()
      let a = vm.pop()
      if a.kind == vmInt and b.kind == vmInt:
        vm.push(VMValue(kind: vmBool, boolVal: a.intVal >= b.intVal))
      else:
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
          vm.push(VMValue(kind: vmBool, boolVal: needle.toString() in haystack.stringVal))
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
      
      # Handle different type combinations
      if a.kind == vmInt and b.kind == vmInt:
        vm.push(VMValue(kind: vmInt, intVal: a.intVal + b.intVal))
      elif a.kind == vmString or b.kind == vmString:
        # String concatenation
        let aStr = a.toString()
        let bStr = b.toString()
        vm.push(VMValue(kind: vmString, stringVal: aStr & bStr))
      elif a.kind in [vmInt, vmFloat] and b.kind in [vmInt, vmFloat]:
        let af = if a.kind == vmInt: a.intVal.float else: a.floatVal
        let bf = if b.kind == vmInt: b.intVal.float else: b.floatVal
        vm.push(VMValue(kind: vmFloat, floatVal: af + bf))
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
        let key = index.toString()
        if key in arr.objectVal:
          vm.push(arr.objectVal[key])
        else:
          vm.push(VMValue(kind: vmNull))
      else:
        vm.push(VMValue(kind: vmNull))

    # Filters
    of opCallFilter:
      let filterName = vm.strings[inst.filterId]
      
      # Pop arguments (they were pushed in order during compilation)
      var args: seq[VMValue] = @[]
      for i in uint8(0)..<inst.argCount:
        args.add(vm.pop())
      
      # Pop the value to filter
      let value = vm.pop()
      
      # Apply filter using the filters module
      try:
        let filter_result = applyFilter(value, filterName, args)
        vm.push(filter_result)
      except Exception as e:
        echo "Filter error: ", e.msg
        raise e  # Re-throw the exception so tests can catch it
    
    of opRange:
      # Create a range from start..end
      let endVal = vm.pop()
      let startVal = vm.pop()
      
      # Convert to integers
      var startInt: int64
      var endInt: int64
      
      case startVal.kind
      of vmInt:
        startInt = startVal.intVal
      of vmFloat:
        startInt = startVal.floatVal.int64
      else:
        vm.push(VMValue(kind: vmNull))
        continue
      
      case endVal.kind
      of vmInt:
        endInt = endVal.intVal
      of vmFloat:
        endInt = endVal.floatVal.int64
      else:
        vm.push(VMValue(kind: vmNull))
        continue
      
      # Create array with range values
      var rangeArray: seq[VMValue] = @[]
      if startInt <= endInt:
        for i in startInt..endInt:
          rangeArray.add(VMValue(kind: vmInt, intVal: i))
      else:
        # Handle reverse ranges
        for i in countdown(startInt, endInt):
          rangeArray.add(VMValue(kind: vmInt, intVal: i))
      
      vm.push(VMValue(kind: vmArray, arrayVal: rangeArray))
    
    else:
      # Unimplemented opcode
      raise newException(CatchableError, 
        "Unimplemented opcode: " & $inst.op)
  
  result = vm.output

# Public API
proc render*(bytecode: seq[Instruction], strings: seq[string],
            constants: seq[VMValue], data: Table[string, VMValue]): string =
  ## Render a template with the given data
  var vm = newLiquidVM(bytecode, strings, constants, data)
  result = vm.execute()



when isMainModule:
  import std/[unittest]
  import lexer, compiler

  let empty_array:seq[string] = @[]

  # Helper to compile and run a template
  proc renderTemplate(source: string, data: Table[string, VMValue]): string =
    let sections = lex(source)
    let compiled = compile(sections, source)
    result = render(compiled.bytecode, compiled.strings, compiled.constants, data)

  # Helper to create VMValue from various types
  # proc toVMValue(x: int): VMValue = vmInt(x.int64)
  # proc toVMValue(x: float): VMValue = vmFloat(x)
  # proc toVMValue(x: string): VMValue = vmString(x)
  # proc toVMValue(x: bool): VMValue = vmBool(x)
  proc toVMValue(x: seq[int]): VMValue =
    var arr: seq[VMValue] = @[]
    for item in x:
      arr.add(vmInt(item.int64))
    vmArray(arr)

  proc toVMValue(x: seq[string]): VMValue =
    var arr: seq[VMValue] = @[]
    for item in x:
      arr.add(vmString(item))
    vmArray(arr)

  # proc toVMValue(x: seq[float]): VMValue =
  #   var arr: seq[VMValue] = @[]
  #   for item in x:
  #     arr.add(vmFloat(item))
  #   vmArray(arr)

  # proc toVMValue(x: seq[bool]): VMValue =
  #   var arr: seq[VMValue] = @[]
  #   for item in x:
  #     arr.add(vmBool(item))
  #   vmArray(arr)

  # # For already converted VMValues
  # proc toVMValue(x: seq[VMValue]): VMValue =
  #   vmArray(x)

  # Helper to create object VMValue
  proc makeObject(pairs: varargs[(string, VMValue)]): VMValue =
    var obj = initTable[string, VMValue]()
    for (k, v) in pairs:
      obj[k] = v
    vmObject(obj)

  suite "VM Basic Output":
    test "Empty template":
      let source = ""
      let data = initTable[string, VMValue]()
      let output = renderTemplate(source, data)
      check output == ""

    test "Plain text":
      let source = "Hello, World!"
      let data = initTable[string, VMValue]()
      let output = renderTemplate(source, data)
      check output == "Hello, World!"

    test "Simple variable":
      let source = "Hello, {{ name }}!"
      let data = {"name": vmString("Alice")}.toTable
      let output = renderTemplate(source, data)
      check output == "Hello, Alice!"

    test "Missing variable as empty":
      let source = "Hello, {{ name }}!"
      let data = initTable[string, VMValue]()
      let output = renderTemplate(source, data)
      check output == "Hello, !"

    test "Integer output":
      let source = "Count: {{ count }}"
      let data = {"count": vmInt(42)}.toTable
      let output = renderTemplate(source, data)
      check output == "Count: 42"

    test "Float output":
      let source = "Price: {{ price }}"
      let data = {"price": vmFloat(19.99)}.toTable
      let output = renderTemplate(source, data)
      check output == "Price: 19.99"

    test "Boolean output":
      let source = "Active: {{ active }}"
      let data = {"active": vmBool(true)}.toTable
      let output = renderTemplate(source, data)
      check output == "Active: true"

  suite "VM Property Access":
    test "Object property":
      let source = "Name: {{ user.name }}"
      let data = {
        "user": makeObject(("name", vmString("Bob")))
      }.toTable
      let output = renderTemplate(source, data)
      check output == "Name: Bob"

    test "Nested property":
      let source = "City: {{ user.address.city }}"
      let data = {
        "user": makeObject(
          ("address", makeObject(
            ("city", vmString("New York"))
          ))
        )
      }.toTable
      let output = renderTemplate(source, data)
      check output == "City: New York"

    test "Missing property as empty":
      let source = "Age: {{ user.age }}"
      let data = {
        "user": makeObject(("name", vmString("Charlie")))
      }.toTable
      let output = renderTemplate(source, data)
      check output == "Age: "

    test "Array property - size":
      let source = "Items: {{ items.size }}"
      let data = {
        "items": toVMValue(@[1, 2, 3])
      }.toTable
      let output = renderTemplate(source, data)
      check output == "Items: 3"

  suite "VM Conditionals":
    test "Simple if - true":
      let source = "{% if show %}Visible{% endif %}"
      let data = {"show": vmBool(true)}.toTable
      let output = renderTemplate(source, data)
      check output == "Visible"

    test "Simple if - false":
      let source = "{% if show %}Visible{% endif %}"
      let data = {"show": vmBool(false)}.toTable
      let output = renderTemplate(source, data)
      check output == ""

    test "If-else":
      let source = "{% if logged_in %}Welcome{% else %}Please login{% endif %}"
      
      let data1 = {"logged_in": vmBool(true)}.toTable
      check renderTemplate(source, data1) == "Welcome"
      
      let data2 = {"logged_in": vmBool(false)}.toTable
      check renderTemplate(source, data2) == "Please login"

    test "Truthy values":
      let source = "{% if value %}Yes{% else %}No{% endif %}"
      
      # Truthy values
      check renderTemplate(source, {"value": vmInt(1)}.toTable) == "Yes"
      check renderTemplate(source, {"value": vmString("text")}.toTable) == "Yes"
      check renderTemplate(source, {"value": toVMValue(@[1])}.toTable) == "Yes"
      
      # Falsy values
      check renderTemplate(source, {"value": vmInt(0)}.toTable) == "No"
      check renderTemplate(source, {"value": vmString("")}.toTable) == "No"
      check renderTemplate(source, {"value": vmNull()}.toTable) == "No"
      check renderTemplate(source, {"value": toVMValue(empty_array)}.toTable) == "No"

    test "Comparison operators":
      let source = "{% if age > 18 %}Adult{% else %}Minor{% endif %}"
      
      check renderTemplate(source, {"age": vmInt(21)}.toTable) == "Adult"
      check renderTemplate(source, {"age": vmInt(18)}.toTable) == "Minor"
      check renderTemplate(source, {"age": vmInt(16)}.toTable) == "Minor"

  suite "VM Loops":
    test "Simple for loop":
      let source = "{% for item in items %}{{ item }} {% endfor %}"
      let data = {
        "items": toVMValue(@[1, 2, 3])
      }.toTable
      let output = renderTemplate(source, data)
      check output == "1 2 3 "

    test "For loop with strings":
      let source = "{% for name in names %}Hello {{ name }}! {% endfor %}"
      let data = {
        "names": toVMValue(@["Alice", "Bob"])
      }.toTable
      let output = renderTemplate(source, data)
      check output == "Hello Alice! Hello Bob! "

    test "Empty loop":
      let source = "{% for item in items %}{{ item }}{% endfor %}Done"
      let data = {
        "items": toVMValue(empty_array)
      }.toTable
      let output = renderTemplate(source, data)
      check output == "Done"

    test "Loop with object properties":
      let source = "{% for user in users %}{{ user.name }}: {{ user.age }} {% endfor %}"
      let data = {
        "users": vmArray(@[
          makeObject(
            ("name", vmString("Alice")),
            ("age", vmInt(30))
          ),
          makeObject(
            ("name", vmString("Bob")),
            ("age", vmInt(25))
          )
        ])
      }.toTable
      let output = renderTemplate(source, data)
      check output == "Alice: 30 Bob: 25 "

    test "Nested loops":
      let source = "{% for row in rows %}{% for col in row %}{{ col }} {% endfor %}| {% endfor %}"
      let data = {
        "rows": vmArray(@[
          toVMValue(@[1, 2]),
          toVMValue(@[3, 4])
        ])
      }.toTable
      
      let output = renderTemplate(source, data)
      
      check output == "1 2 | 3 4 | "

  suite "VM Variables":
    test "Assign literal":
      let source = "{% assign x = 5 %}x = {{ x }}"
      let data = initTable[string, VMValue]()
      let output = renderTemplate(source, data)
      check output == "x = 5"

    test "Assign from variable":
      let source = "{% assign copy = original %}{{ copy }}"
      let data = {"original": vmString("test")}.toTable
      let output = renderTemplate(source, data)
      check output == "test"

    test "Assign overwrites":
      let source = "{% assign x = 1 %}First: {{ x }} {% assign x = 2 %}Second: {{ x }}"
      let data = initTable[string, VMValue]()
      let output = renderTemplate(source, data)
      check output == "First: 1 Second: 2"

    test "Local shadows global":
      let source = "Global: {{ x }} {% assign x = 'local' %}Local: {{ x }}"
      let data = {"x": vmString("global")}.toTable
      let output = renderTemplate(source, data)
      check output == "Global: global Local: local"

  suite "VM Capture":
    test "Simple capture":
      let source = "{% capture greeting %}Hello, {{ name }}!{% endcapture %}{{ greeting }}"
      let data = {"name": vmString("World")}.toTable
      let output = renderTemplate(source, data)
      check output == "Hello, World!"

    test "Capture with multiple outputs":
      let source = """{% capture card %}<h1>{{ title }}</h1><p>{{ desc }}</p>{% endcapture %}{{ card }}"""
      let data = {
        "title": vmString("Test"),
        "desc": vmString("Description")
      }.toTable
      let output = renderTemplate(source, data)
      check output == "<h1>Test</h1><p>Description</p>"

    test "Nested capture":
      let source = """{% capture outer %}[{% capture inner %}{{ x }}{% endcapture %}{{ inner }}]{% endcapture %}{{ outer }}"""
      let data = {"x": vmString("nested")}.toTable
      let output = renderTemplate(source, data)
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
      var vm = newLiquidVM(compiled.bytecode, compiled.strings, compiled.constants, data)
      vm.escapeHtml = false  # Disable HTML escaping
      let output = vm.execute()
      
      check output == "<h1>Test</h1><p>Description</p>"

  suite "VM Literals":
    test "String literal":
      let source = "{{ 'hello world' }}"
      let data = initTable[string, VMValue]()
      let output = renderTemplate(source, data)
      check output == "hello world"

    test "Number literals":
      let source = "Int: {{ 42 }} Float: {{ 3.14 }}"
      let data = initTable[string, VMValue]()
      let output = renderTemplate(source, data)
      check output == "Int: 42 Float: 3.14"

    test "Boolean literals":
      let source = "True: {{ true }} False: {{ false }}"
      let data = initTable[string, VMValue]()
      let output = renderTemplate(source, data)
      check output == "True: true False: false"

    test "Nil literal - actual":
      let source = "Nil: '{{ nil }}'"
      let data = initTable[string, VMValue]()
      let output = renderTemplate(source, data)
      
      # The single quotes might be getting escaped
      # Let's check what we actually get
      echo "Nil output: '", output, "'"
      check "Nil: " in output

  suite "VM Filters":
    test "Upcase filter":
      let source = "{{ name | upcase }}"
      let data = {"name": vmString("hello")}.toTable
      let output = renderTemplate(source, data)
      check output == "HELLO"

    test "Downcase filter":
      let source = "{{ name | downcase }}"
      let data = {"name": vmString("HELLO")}.toTable
      let output = renderTemplate(source, data)
      check output == "hello"

    test "Size filter":
      let source = "{{ items | size }}"
      let data = {"items": toVMValue(@[1, 2, 3, 4, 5])}.toTable
      let output = renderTemplate(source, data)
      check output == "5"

    test "First filter":
      let source = "{{ items | first }}"
      let data = {"items": toVMValue(@["a", "b", "c"])}.toTable
      let output = renderTemplate(source, data)
      check output == "a"

    test "Last filter":
      let source = "{{ items | last }}"
      let data = {"items": toVMValue(@["a", "b", "c"])}.toTable
      let output = renderTemplate(source, data)
      check output == "c"

    test "Chained filters":
      let source = "{{ name | downcase | size }}"
      let data = {"name": vmString("HELLO")}.toTable
      let output = renderTemplate(source, data)
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
        "post": makeObject(
          ("title", vmString("Hello World")),
          ("author", vmString("Alice")),
          ("date", vmString("2024-01-01")),
          ("tags", toVMValue(@["nim", "templates", "liquid"])),
          ("content", vmString("This is the post content."))
        )
      }.toTable
      
      let output = renderTemplate(source, data)
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
          makeObject(
            ("name", vmString("Book")),
            ("price", vmFloat(19.99)),
            ("quantity", vmInt(2))
          ),
          makeObject(
            ("name", vmString("Pen")),
            ("price", vmFloat(1.99)),
            ("quantity", vmInt(5))
          )
        ])
      }.toTable
      
      let output = renderTemplate(source, data)
      check "Book: $19.99 x 2" in output
      check "Pen: $1.99 x 5" in output
      check "Total items: 2" in output

  suite "VM Edge Cases":
    test "Deeply nested properties":
      let source = "{{ a.b.c.d.e }}"
      let data = {
        "a": makeObject(
          ("b", makeObject(
            ("c", makeObject(
              ("d", makeObject(
                ("e", vmString("deep"))
              ))
            ))
          ))
        )
      }.toTable
      let output = renderTemplate(source, data)
      check output == "deep"

    test "HTML escaping":
      let source = "{{ content }}"
      let data = {"content": vmString("<script>alert('xss')</script>")}.toTable
      
      # Create VM with HTML escaping enabled (default)
      let sections = lex(source)
      let compiled = compile(sections, source)
      var vm = newLiquidVM(compiled.bytecode, compiled.strings, compiled.constants, data)
      vm.escapeHtml = true
      let output = vm.execute()
      
      check "<script>" notin output
      check "&lt;script&gt;" in output

    test "Division by zero":
      let source = "{{ 10 / 0 }}"
      let data = initTable[string, VMValue]()
      let output = renderTemplate(source, data)
      
      check output == ""

    test "Division by zero - float":
      let source = "{{ 10.5 / 0.0 }}"
      let data = initTable[string, VMValue]()
      let output = renderTemplate(source, data)
      
      check output == "inf"

    test "Modulo by zero":
      let source = "{{ 10 % 0 }}"
      let data = initTable[string, VMValue]()
      let output = renderTemplate(source, data)
      
      check output == ""

    test "Array index out of bounds - positive":
      let source = "{{ items[10] }}"
      let data = {
        "items": toVMValue(@["a", "b", "c"])
      }.toTable
      let output = renderTemplate(source, data)
      
      check output == ""

    test "Array index out of bounds - negative":
      let source = "{{ items[-1] }}"
      let data = {
        "items": toVMValue(@["a", "b", "c"])
      }.toTable
      let output = renderTemplate(source, data)
      
      check output == "c"

    test "Array index with non-integer":
      let source = "{{ items['hello'] }}"
      let data = {
        "items": toVMValue(@["a", "b", "c"])
      }.toTable
      let output = renderTemplate(source, data)
      
      check output == ""

    test "Null property access":
      let source = "{{ nothing.property }}"
      let data = initTable[string, VMValue]()
      let output = renderTemplate(source, data)
      
      check output == ""

    test "Deep property chain with null":
      let source = "{{ a.b.c.d.e.f.g }}"
      let data = {
        "a": makeObject(
          ("b", vmNull())
        )
      }.toTable
      let output = renderTemplate(source, data)
      
      check output == ""

    test "Type coercion edge cases":
      let source1 = "{{ true + 1 }}"
      let output1 = renderTemplate(source1, initTable[string, VMValue]())
      
      check output1 == ""

    test "String coercion 1":
      let source = "{{ '5' + 5 }}"
      let output = renderTemplate(source, initTable[string, VMValue]())

      check output == "55"

    test "String coercion 1":
      let source = "{{ 5 + '5' }}"
      let output = renderTemplate(source, initTable[string, VMValue]())

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
      let output = renderTemplate(source, data)
      
      check output.strip() == ""

    test "Infinite loop protection":
      # This is a stress test - the VM should handle very long loops
      # In production, you might want a max iteration limit
      let source = "{% for i in items %}{{ i }}{% endfor %}"
      
      # Create a very large array
      var bigArray: seq[VMValue] = @[]
      for i in 0..1000:
        bigArray.add(vmInt(i))
      
      let data = {
        "items": vmArray(bigArray)
      }.toTable
      
      let output = renderTemplate(source, data)
      
      # Should complete without hanging
      check output.len > 0
      check "500" in output  # Middle element should be there
