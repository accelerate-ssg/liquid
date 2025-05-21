import strutils, json, sequtils

import ./filters/[strings]

import parser, shared, filters

proc evaluate*(node: Node, context: Context): JsonNode

proc evaluateVariable(node: Node, context: Context): JsonNode =
  if node.isNil or node.kind != nkVariable: return newJNull()

  let parts = node.name.split('.')
  var current = context
  
  for part in parts:
    if current.kind == JObject and part in current:
      current = current[part]
    else:
      return newJNull()  # Return null if the variable is not found
  
  current

proc applyOperator(op: string, left, right: JsonNode): JsonNode =
  case op
  of "+":
    if left.kind == JInt and right.kind == JInt:
      return newJInt(left.getInt + right.getInt)
    elif left.kind == JFloat or right.kind == JFloat:
      return newJFloat(left.getFloat + right.getFloat)
    elif left.kind == JString and right.kind == JString:
      return newJString(left.getStr & right.getStr)
  of "-":
    if left.kind == JInt and right.kind == JInt:
      return newJInt(left.getInt - right.getInt)
    elif left.kind == JFloat or right.kind == JFloat:
      return newJFloat(left.getFloat - right.getFloat)
  of "*":
    if left.kind == JInt and right.kind == JInt:
      return newJInt(left.getInt * right.getInt)
    elif left.kind == JFloat or right.kind == JFloat:
      return newJFloat(left.getFloat * right.getFloat)
  of "/":
    if right.getFloat == 0:
      return newJNull()  # Handle division by zero
    elif left.kind == JInt and right.kind == JInt:
      return newJFloat(left.getInt.float / right.getInt.float)
    elif left.kind == JFloat or right.kind == JFloat:
      return newJFloat(left.getFloat / right.getFloat)
  of "==":
    return newJBool(left == right)
  of "!=":
    return newJBool(left != right)
  of "<", "<=", ">", ">=":
    if left.kind == JInt and right.kind == JInt:
      let leftInt = left.getInt
      let rightInt = right.getInt
      case op
      of "<": return newJBool(leftInt < rightInt)
      of "<=": return newJBool(leftInt <= rightInt)
      of ">": return newJBool(leftInt > rightInt)
      of ">=": return newJBool(leftInt >= rightInt)
      else: discard
    elif left.kind == JFloat or right.kind == JFloat:
      let leftFloat = left.getFloat
      let rightFloat = right.getFloat
      case op
      of "<": return newJBool(leftFloat < rightFloat)
      of "<=": return newJBool(leftFloat <= rightFloat)
      of ">": return newJBool(leftFloat > rightFloat)
      of ">=": return newJBool(leftFloat >= rightFloat)
      else: discard
    elif left.kind == JString and right.kind == JString:
      let leftStr = left.getStr
      let rightStr = right.getStr
      case op
      of "<": return newJBool(leftStr < rightStr)
      of "<=": return newJBool(leftStr <= rightStr)
      of ">": return newJBool(leftStr > rightStr)
      of ">=": return newJBool(leftStr >= rightStr)
      else: discard
  of "and":
    return newJBool(left.getBool and right.getBool)
  of "or":
    return newJBool(left.getBool or right.getBool)
  else:
    echo "Unknown operator: ", op
  return newJNull()

proc isWhitespaceOnly(node: JsonNode): bool =
  if node.kind == JString:
    return node.getStr().strip().len == 0
  elif node.kind == JArray:
    return node.elems.allIt(isWhitespaceOnly(it))
  else:
    return false

proc isEmpty(node: JsonNode): bool =
  case node.kind
  of JString:
    return node.getStr.len == 0
  of JArray:
    return node.len == 0
  of JObject:
    return node.len == 0
  of JNull:
    return true
  else:
    return false

proc evaluate*(node: Node, context: Context): JsonNode =
  try:
    case node.kind
    of nkTemplate:
      result = newJArray()
      for child in node.children:
        let childResult = evaluate(child, context)
        if not isWhitespaceOnly(childResult):
          result.add(childResult)
      if result.len == 0:
        result = newJString("")
      elif result.len == 1:
        result = result[0]
    
    of nkText:
      result = newJString(node.textValue)
    
    of nkOutput:
      result = evaluate(node.expression, context)
      if result.kind == JNull:
        result = newJString("")
    
    of nkVariable:
      result = evaluateVariable(node, context)
      if result.kind == JNull:
        result = newJString("")
    
    of nkFilter:
      let value = evaluate(node.arguments[0], context)
      var arguments: seq[JsonNode] = @[]
      for argument in node.arguments[1..^1]:
        arguments.add(evaluate(argument, context))
      result = applyFilter(value, node.filterName, arguments, context)
      if result.kind == JNull:
        result = newJString("")
    
    of nkIfTag, nkUnlessTag:
      for branch in node.branches:
        let conditionValue = evaluate(branch.condition, context)
        let conditionMet = 
          if node.kind == nkIfTag:
            conditionValue.kind == JBool and conditionValue.getBool
          else:  # nkUnlessTag
            conditionValue.kind != JBool or not conditionValue.getBool
        
        if conditionMet:
          result = evaluate(branch.body, context)
          if not isWhitespaceOnly(result):
            return result
      
      # If no condition was met, evaluate the else branch (if it exists)
      if not isNil(node.elseBranch):
        result = evaluate(node.elseBranch, context)
        if not isWhitespaceOnly(result):
          return result
      
      result = newJString("")
    
    of nkLiteral:
      case node.literalValue
      of "true": result = newJBool(true)
      of "0.0": result = newJBool(true)
      of "false": result = newJBool(false)
      of "nil": result = newJNull()

      else:
        try:
          result = newJInt(parseInt(node.literalValue))
        except ValueError:
          try:
            result = newJFloat(parseFloat(node.literalValue))
          except ValueError:
            result = newJString(node.literalValue)
    
    of nkForTag:
      let iterableValue = evaluate(node.iterable, context)
      result = newJString("")
      if iterableValue.kind == JArray:
        for item in iterableValue:
          var loopContext = context
          loopContext[node.loopVar] = item
          result = newJString(result.getStr & evaluate(node.body, loopContext).getStr)
    
    of nkAssignTag:
      let value = evaluate(node.assignValue, context)
      context[node.varName] = value
      result = newJString("")
    
    of nkOperator:
      let left = evaluate(node.left, context)
      let right = evaluate(node.right, context)
      result = applyOperator(node.op, left, right)
      if result.kind == JNull:
        result = newJString("")

    of nkEmpty:
      let targetValue = evaluate(node.target, context)
      result = newJBool(isEmpty(targetValue))
      
  except CatchableError as e:
    echo "Error in template evaluation: " & e.msg
    result = newJString("")

proc renderTemplate*(node: Node, context: Context): string =
  try:
    result = evaluate(node, context).getStr
  except CatchableError as e:
    echo "Error in template rendering: " & e.msg
    result = ""
