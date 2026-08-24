import std/[json, tables]
import bytecode

# Convert JsonNode to VMValue
proc json_to_vm_value*(node: JsonNode): VMValue =
  ## Convert a JsonNode to VMValue for use as template context
  case node.kind
  of JNull:
    result = VMValue(kind: vmNull)
    
  of JBool:
    result = VMValue(kind: vmBool, boolVal: node.getBool())
    
  of JInt:
    result = VMValue(kind: vmInt, intVal: node.getInt())
    
  of JFloat:
    result = VMValue(kind: vmFloat, floatVal: node.getFloat())
    
  of JString:
    result = VMValue(kind: vmString, stringVal: node.getStr())
    
  of JArray:
    var arr: seq[VMValue] = @[]
    for item in node.getElems():
      arr.add(json_to_vm_value(item))
    result = VMValue(kind: vmArray, arrayVal: arr)
    
  of JObject:
    var obj = initOrderedTable[string, VMValue]()
    for key, value in node.getFields():
      obj[key] = json_to_vm_value(value)
    result = VMValue(kind: vmObject, objectVal: obj)

# Convert JsonNode to template context (Table[string, VMValue])
proc json_to_context*(node: JsonNode): Table[string, VMValue] =
  ## Convert a JsonNode to a context table for template rendering
  ## The JsonNode should be an object at the root level
  result = initTable[string, VMValue]()
  
  case node.kind
  of JObject:
    for key, value in node.getFields():
      result[key] = json_to_vm_value(value)
  else:
    # If not an object, wrap it in a "data" key
    result["data"] = json_to_vm_value(node)

# Convenience proc to parse JSON string directly to context
proc parse_json_context*(jsonStr: string): Table[string, VMValue] =
  ## Parse a JSON string and convert to template context
  let node = parseJson(jsonStr)
  result = json_to_context(node)

# Helper to create VMValue from common Nim types (for manual context building)
proc to_vm_value*(x: bool): VMValue = VMValue(kind: vmBool, boolVal: x)
proc to_vm_value*(x: int): VMValue = VMValue(kind: vmInt, intVal: x.int64)
proc to_vm_value*(x: int64): VMValue = VMValue(kind: vmInt, intVal: x)
proc to_vm_value*(x: float32): VMValue = VMValue(kind: vmFloat, floatVal: x.float64)
proc to_vm_value*(x: float64): VMValue = VMValue(kind: vmFloat, floatVal: x)
proc to_vm_value*(x: string): VMValue = VMValue(kind: vmString, stringVal: x)
proc to_vm_value*(x: seq[VMValue]): VMValue = VMValue(kind: vmArray, arrayVal: x)
proc to_vm_value*(x: OrderedTable[string, VMValue]): VMValue = VMValue(kind: vmObject, objectVal: x)
proc to_vm_value*(x: Table[string, VMValue]): VMValue =
  var ordered = initOrderedTable[string, VMValue]()
  for k, v in x:
    ordered[k] = v
  VMValue(kind: vmObject, objectVal: ordered)


