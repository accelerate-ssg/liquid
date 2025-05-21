import json, tables, macros

type
  Context* = JsonNode
  FilterFunc* = proc(value: JsonNode, args: varargs[JsonNode]): JsonNode

var filters* = initTable[string, FilterFunc]()

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
  let procNameStr = $procName  # Convert procName to string
  let params = procDef.params
  let returnType = params[0]
  let inputType = params[1][1] # Type of the first parameter (input)

  # Create an intermediate function with the original signature
  let intermediateProcName = ident(procNameStr & "Impl")
  let intermediateProc = copyNimTree(procDef)
  intermediateProc.name = intermediateProcName

  var newBody = newStmtList()
  let expectedArgCount = params.len - 2 # -2 for return type and input parameter

  # Add argument count check
  newBody.add quote do:
    if args.len != `expectedArgCount`:
      raise newException(ValueError, "Expected " & $`expectedArgCount` & " arguments, got " & $args.len)

  # Convert the 'value' parameter
  let convertedValueIdent = genSym(nskLet, "convertedValue")
  newBody.add quote do:
    let `convertedValueIdent` = 
      when `inputType` is string: value.getStr()
      elif `inputType` is int: value.getInt()
      elif `inputType` is float: value.getFloat()
      elif `inputType` is bool: value.getBool()
      else: raise newException(ValueError, "Unsupported input type")

  # Convert other parameters
  var callParams = @[convertedValueIdent]
  for i in 2 ..< params.len:
    let paramName = params[i][0]
    let paramType = params[i][1]
    let convertedParamIdent = genSym(nskLet, paramName.strVal & "Converted")
    newBody.add quote do:
      let `convertedParamIdent` = 
        try:
          when `paramType` is int: args[`i`-2].getInt()
          elif `paramType` is float: args[`i`-2].getFloat()
          elif `paramType` is string: args[`i`-2].getStr()
          elif `paramType` is bool: args[`i`-2].getBool()
          else: raise newException(ValueError, "Unsupported type")
        except CatchableError:
          raise newException(ValueError, "Type mismatch for argument " & $(`i`-1))
    callParams.add(convertedParamIdent)

  # Call the intermediate function
  let procCall = newCall(intermediateProcName, callParams)

  # Convert the result back to JsonNode
  newBody.add quote do:
    %`procCall`

  # Create the new procedure
  let newProcDef = newProc(
    name = procName,
    params = [ident"JsonNode", newIdentDefs(ident"value", ident"JsonNode"), newIdentDefs(ident"args", nnkBracketExpr.newTree(ident"varargs", ident"JsonNode"))],
    body = newBody,
    pragmas = nnkPragma.newTree(ident"nimcall")
  )

  # Return the final AST
  result = newStmtList(
    intermediateProc,
    newProcDef,
    quote do:
      filters[`procNameStr`] = `procName`
  )

  