import json, tables, std/macros
import compiler/types
export types

type
  Context* = JsonNode
  FilterFunc* = proc(value: VMValue, args: varargs[VMValue]): VMValue

var filters* = initTable[string, FilterFunc]()

# Enhanced macro that registers the filter and adds argument validation
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
  
  # Analyze the function signature to determine expected argument count
  let formalParams = procDef[3] # nnkFormalParams
  var expectedArgCount = 0
  var hasVarargs = false
  
  # Skip return type (index 0) and first parameter (value: VMValue, index 1)
  # Count remaining parameters
  for i in 2..<formalParams.len:
    let param = formalParams[i]
    if param.kind == nnkIdentDefs:
      let paramType = param[^2] # Type is second-to-last node
      if (paramType.kind == nnkCommand and paramType[0].strVal == "varargs") or
         (paramType.kind == nnkBracketExpr and paramType[0].strVal == "varargs"):
        hasVarargs = true
        break
      else:
        # Count the number of identifiers in this parameter group
        expectedArgCount += param.len - 2 # exclude type and default value
  
  # Create a wrapper function that validates arguments
  let wrapperName = newIdentNode(procNameStr & "_impl")
  let originalName = procName
  
  # Rename the original proc
  procDef[0] = wrapperName
  
  # Create the wrapper proc
  let wrapperProc = if hasVarargs:
    # For varargs functions, don't add validation (they handle it themselves)
    quote do:
      proc `originalName`(value: VMValue, args: varargs[VMValue]): VMValue =
        `wrapperName`(value, args)
  else:
    # For fixed-arg functions, generate the appropriate call based on arg count
    if expectedArgCount == 0:
      quote do:
        proc `originalName`(value: VMValue, args: varargs[VMValue]): VMValue =
          if args.len != 0:
            raise newException(ValueError, `procNameStr` & " filter takes no arguments")
          `wrapperName`(value)
    elif expectedArgCount == 1:
      quote do:
        proc `originalName`(value: VMValue, args: varargs[VMValue]): VMValue =
          if args.len != 1:
            if args.len == 0:
              raise newException(ValueError, `procNameStr` & " filter requires exactly 1 argument")
            else:
              raise newException(ValueError, `procNameStr` & " filter takes at most 1 argument")
          `wrapperName`(value, args[0])
    elif expectedArgCount == 2:
      quote do:
        proc `originalName`(value: VMValue, args: varargs[VMValue]): VMValue =
          if args.len != 2:
            raise newException(ValueError, `procNameStr` & " filter requires exactly 2 arguments")
          `wrapperName`(value, args[0], args[1])
    else:
      # For more than 2 args, fall back to generic handling
      quote do:
        proc `originalName`(value: VMValue, args: varargs[VMValue]): VMValue =
          if args.len != `expectedArgCount`:
            raise newException(ValueError, `procNameStr` & " filter requires exactly " & $`expectedArgCount` & " arguments")
          # This will need manual handling for 3+ args - for now just pass through
          `wrapperName`(value, args)
  
  result = newStmtList(
    procDef,      # Original proc with new name
    wrapperProc,  # Wrapper proc with validation
    quote do:
      filters[`procNameStr`] = `originalName`
  )