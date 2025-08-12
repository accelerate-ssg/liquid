import json, tables, std/macros
import compiler/types
export types

type
  Context* = JsonNode
  FilterFunc* = proc(value: VMValue, args: varargs[VMValue]): VMValue

var filters* = initTable[string, FilterFunc]()

# Simple macro that just registers the filter
macro createFilter*(body: untyped): untyped =
  var procDef: NimNode
  if body.kind == nnkStmtList:
    if body.len != 1 or body[0].kind != nnkProcDef:
      error("Expected a single procedure definition", body)
    procDef = body[0]
  elif body.kind == nnkProcDef:
    procDef = body
  else:
    error("Expected a procedure definition", body)

  let procName = procDef.name
  let procNameStr = $procName
  
  # The filter proc should already have the right signature
  result = newStmtList(
    procDef,
    quote do:
      filters[`procNameStr`] = `procName`
  )