import std/[json, tables]
import types

# Convert JsonNode to VMValue
proc jsonToVMValue*(node: JsonNode): VMValue =
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
      arr.add(jsonToVMValue(item))
    result = VMValue(kind: vmArray, arrayVal: arr)
    
  of JObject:
    var obj = initTable[string, VMValue]()
    for key, value in node.getFields():
      obj[key] = jsonToVMValue(value)
    result = VMValue(kind: vmObject, objectVal: obj)

# Convert JsonNode to template context (Table[string, VMValue])
proc jsonToContext*(node: JsonNode): Table[string, VMValue] =
  ## Convert a JsonNode to a context table for template rendering
  ## The JsonNode should be an object at the root level
  result = initTable[string, VMValue]()
  
  case node.kind
  of JObject:
    for key, value in node.getFields():
      result[key] = jsonToVMValue(value)
  else:
    # If not an object, wrap it in a "data" key
    result["data"] = jsonToVMValue(node)

# Convenience proc to parse JSON string directly to context
proc parseJsonContext*(jsonStr: string): Table[string, VMValue] =
  ## Parse a JSON string and convert to template context
  let node = parseJson(jsonStr)
  result = jsonToContext(node)

# Helper to create VMValue from common Nim types (for manual context building)
proc toVMValue*(x: bool): VMValue = VMValue(kind: vmBool, boolVal: x)
proc toVMValue*(x: int): VMValue = VMValue(kind: vmInt, intVal: x.int64)
proc toVMValue*(x: int64): VMValue = VMValue(kind: vmInt, intVal: x)
proc toVMValue*(x: float32): VMValue = VMValue(kind: vmFloat, floatVal: x.float64)
proc toVMValue*(x: float64): VMValue = VMValue(kind: vmFloat, floatVal: x)
proc toVMValue*(x: string): VMValue = VMValue(kind: vmString, stringVal: x)
proc toVMValue*(x: seq[VMValue]): VMValue = VMValue(kind: vmArray, arrayVal: x)
proc toVMValue*(x: Table[string, VMValue]): VMValue = VMValue(kind: vmObject, objectVal: x)

# Convert VMValue to JsonNode (reverse conversion)
proc vmValueToJson*(v: VMValue): JsonNode =
  ## Convert a VMValue back to JsonNode
  case v.kind
  of vmNull:
    result = newJNull()
  of vmBool:
    result = newJBool(v.boolVal)
  of vmInt:
    result = newJInt(v.intVal)
  of vmFloat:
    result = newJFloat(v.floatVal)
  of vmString:
    result = newJString(v.stringVal)
  of vmArray:
    result = newJArray()
    for item in v.arrayVal:
      result.add(vmValueToJson(item))
  of vmObject:
    result = newJObject()
    for key, val in v.objectVal:
      result[key] = vmValueToJson(val)
  of vmLazy:
    # Evaluate lazy value and convert
    let evaluatedValue = v.lazyFn()
    result = vmValueToJson(evaluatedValue)
  of vmIterator:
    # Convert iterator to array by materializing all values
    result = newJArray()
    for i in 0..<v.iterLen:
      let item = v.iterFn(i)
      result.add(vmValueToJson(item))

