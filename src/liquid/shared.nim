import json, tables, macros, times

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
  if expectedArgCount > 0:
    newBody.add quote do:
      if args.len != `expectedArgCount`:
        raise newException(ValueError, "Expected " & $`expectedArgCount` & " arguments, got " & $args.len)

  # Convert the 'value' parameter
  let convertedValueIdent = genSym(nskLet, "convertedValue")
  
  # Check if the input type is seq[JsonNode]
  let isSeqJsonNode = inputType.kind == nnkBracketExpr and 
                      inputType[0].strVal == "seq" and 
                      inputType[1].strVal == "JsonNode"
  
  if isSeqJsonNode:
    newBody.add quote do:
      let `convertedValueIdent` = 
        if value.kind == JArray:
          value.getElems()
        else:
          raise newException(ValueError, "Expected array input")
  else:
    newBody.add quote do:
      let `convertedValueIdent` = 
        when `inputType` is string: value.getStr()
        elif `inputType` is int: value.getInt()
        elif `inputType` is float: value.getFloat()
        elif `inputType` is bool: value.getBool()
        elif `inputType` is JsonNode: value
        elif `inputType` is DateTime: 
          # Special handling for DateTime - assume it's passed as JsonNode
          value
        else: value  # Pass through for other types

  # Convert other parameters
  var callParams = @[convertedValueIdent]
  for i in 2 ..< params.len:
    let paramName = params[i][0]
    let paramType = params[i][1]
    let convertedParamIdent = genSym(nskLet, paramName.strVal & "Converted")
    
    # Check if the parameter type is seq[JsonNode]
    let isParamSeqJsonNode = paramType.kind == nnkBracketExpr and 
                            paramType[0].strVal == "seq" and 
                            paramType[1].strVal == "JsonNode"
    
    if isParamSeqJsonNode:
      newBody.add quote do:
        let `convertedParamIdent` = 
          try:
            if args[`i`-2].kind == JArray:
              args[`i`-2].getElems()
            else:
              raise newException(ValueError, "Expected array for parameter " & $(`i`-1))
          except CatchableError:
            raise newException(ValueError, "Type mismatch for argument " & $(`i`-1))
    else:
      newBody.add quote do:
        let `convertedParamIdent` = 
          try:
            when `paramType` is int: args[`i`-2].getInt()
            elif `paramType` is float: args[`i`-2].getFloat()
            elif `paramType` is string: args[`i`-2].getStr()
            elif `paramType` is bool: args[`i`-2].getBool()
            elif `paramType` is JsonNode: args[`i`-2]
            else: args[`i`-2]  # Pass through for other types
          except CatchableError:
            raise newException(ValueError, "Type mismatch for argument " & $(`i`-1))
    
    callParams.add(convertedParamIdent)

  # Call the intermediate function
  let procCall = newCall(intermediateProcName, callParams)

  # Convert the result back to JsonNode based on return type
  let isJsonNode = returnType.kind == nnkIdent and returnType.strVal == "JsonNode"
  let isBool = returnType.kind == nnkIdent and returnType.strVal == "bool"
  let isInt = returnType.kind == nnkIdent and returnType.strVal == "int"
  let isFloat = returnType.kind == nnkIdent and returnType.strVal == "float"
  let isString = returnType.kind == nnkIdent and returnType.strVal == "string"
  let isReturnSeqJsonNode = returnType.kind == nnkBracketExpr and 
                            returnType[0].strVal == "seq" and 
                            returnType[1].strVal == "JsonNode"
  
  if isJsonNode:
    newBody.add quote do:
      `procCall`
  elif isBool:
    newBody.add quote do:
      newJBool(`procCall`)
  elif isInt:
    newBody.add quote do:
      newJInt(`procCall`)
  elif isFloat:
    newBody.add quote do:
      newJFloat(`procCall`)
  elif isString:
    newBody.add quote do:
      newJString(`procCall`)
  elif isReturnSeqJsonNode:
    newBody.add quote do:
      let arr = newJArray()
      for item in `procCall`:
        arr.add(item)
      arr
  else:
    newBody.add quote do:
      %`procCall`

  # Create a new name for the wrapper function to avoid conflicts
  let wrapperProcName = ident(procNameStr & "Filter")
  
  # Create the new procedure
  let newProcDef = newProc(
    name = wrapperProcName,
    params = [ident"JsonNode", newIdentDefs(ident"value", ident"JsonNode"), newIdentDefs(ident"args", nnkBracketExpr.newTree(ident"varargs", ident"JsonNode"))],
    body = newBody,
    pragmas = nnkPragma.newTree(ident"nimcall")
  )

  # Return the final AST
  result = newStmtList(
    intermediateProc,
    newProcDef,
    quote do:
      filters[`procNameStr`] = `wrapperProcName`
  )
  
  # Debug output
  # echo result.repr

  