# JSON Bridge: Convert between std/json JsonNode and Liquid VMValue
# =================================================================
# Provides bidirectional conversion so that callers using JsonNode
# (e.g. acc2's context tree) can feed data into the Liquid VM
# and read structured results back.

import std/[json, tables]
import bytecode
import vm_types

proc json_to_vmvalue*(node: JsonNode): VMValue =
  ## Convert a JsonNode tree into a VMValue tree.
  if node.isNil:
    return vm_null()

  case node.kind
  of JNull:
    return vm_null()
  of JBool:
    return vm_bool(node.getBool)
  of JInt:
    return vm_int(node.getInt.int64)
  of JFloat:
    return vm_float(node.getFloat)
  of JString:
    return vm_string(node.getStr)
  of JArray:
    var arr: seq[VMValue] = @[]
    for elem in node:
      arr.add(json_to_vmvalue(elem))
    return vm_array(arr)
  of JObject:
    var obj = initOrderedTable[string, VMValue]()
    for key, val in node:
      obj[key] = json_to_vmvalue(val)
    return vm_object(obj)

proc json_to_vm_table*(node: JsonNode): Table[string, VMValue] =
  ## Convert a JObject into a flat Table[string, VMValue] suitable
  ## for passing as the `data` parameter to the Liquid VM.
  ## Non-object nodes return an empty table.
  result = initTable[string, VMValue]()
  if node.isNil or node.kind != JObject:
    return
  for key, val in node:
    result[key] = json_to_vmvalue(val)

proc vmvalue_to_json*(val: VMValue): JsonNode =
  ## Convert a VMValue tree back into a JsonNode tree.
  case val.kind
  of vmNull:
    return newJNull()
  of vmEmpty:
    return newJNull()
  of vmBool:
    return newJBool(val.boolVal)
  of vmInt:
    return newJInt(val.intVal)
  of vmFloat:
    return newJFloat(val.floatVal)
  of vmString:
    return newJString(val.stringVal)
  of vmArray:
    var arr = newJArray()
    for elem in val.arrayVal:
      arr.add(vmvalue_to_json(elem))
    return arr
  of vmObject:
    var obj = newJObject()
    for key, v in val.objectVal:
      obj[key] = vmvalue_to_json(v)
    return obj
