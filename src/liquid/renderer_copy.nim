import strutils, json, sequtils

import types, shared, filters

proc evaluate*(node: Node, context: Context): JsonNode

proc evaluateVariable(node: Node, context: Context): JsonNode =
  if node.isNil or node.kind != nkVariable: return newJNull()

  var current = context
  
  # Navigate through segments
  for segment in node.segments:
    if segment.kind == nkString:
      let key = segment.strVal
      if current.kind == JObject and current.hasKey(key):
        current = current[key]
      elif current.kind == JArray:
        # Try to parse as array index
        try:
          var idx = parseInt(key)
          # Handle negative indices
          if idx < 0:
            idx = current.len + idx
          if idx >= 0 and idx < current.len:
            current = current[idx]
          else:
            return newJNull()
        except:
          return newJNull()
      else:
        return newJNull()
    else:
      # Handle dynamic segments (like array[index])
      let segmentValue = evaluate(segment, context)
      if segmentValue.kind == JString:
        let key = segmentValue.getStr
        if current.kind == JObject and current.hasKey(key):
          current = current[key]
        else:
          return newJNull()
      elif segmentValue.kind == JInt:
        var idx = segmentValue.getInt
        if current.kind == JArray:
          # Handle negative indices
          if idx < 0:
            idx = current.len + idx
          if idx >= 0 and idx < current.len:
            current = current[idx]
          else:
            return newJNull()
        else:
          return newJNull()
      else:
        return newJNull()
  
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
    # Liquid's truthiness: false and nil are falsy, everything else is truthy
    let leftTruthy = not (left.kind == JBool and not left.getBool) and left.kind != JNull
    let rightTruthy = not (right.kind == JBool and not right.getBool) and right.kind != JNull
    return newJBool(leftTruthy and rightTruthy)
  of "or":
    # Liquid's truthiness: false and nil are falsy, everything else is truthy
    let leftTruthy = not (left.kind == JBool and not left.getBool) and left.kind != JNull
    let rightTruthy = not (right.kind == JBool and not right.getBool) and right.kind != JNull
    return newJBool(leftTruthy or rightTruthy)
  of "contains":
    if left.kind == JString and right.kind == JString:
      return newJBool(left.getStr.contains(right.getStr))
    elif left.kind == JArray:
      return newJBool(left.contains(right))
    else:
      return newJBool(false)
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
    of nkOutput:
      # Output nodes contain children to evaluate
      if node.children.len > 0:
        result = evaluate(node.children[0], context)
        if result.kind == JNull:
          result = newJString("")
      else:
        result = newJString("")
    
    of nkVariable:
      result = evaluateVariable(node, context)
      if result.kind == JNull:
        result = newJString("")
    
    of nkString:
      result = newJString(node.strVal)
    
    of nkNumber:
      if node.numVal == node.numVal.int.float:
        result = newJInt(node.numVal.int)
      else:
        result = newJFloat(node.numVal)
    
    of nkBoolean:
      result = newJBool(node.boolVal)
    
    of nkNil:
      result = newJNull()
    
    of nkArray:
      result = newJArray()
      for element in node.elements:
        result.add(evaluate(element, context))
    
    of nkRange:
      # Evaluate range into an array
      let startVal = evaluate(node.rangeStart, context)
      let endVal = evaluate(node.rangeEnd, context)
      result = newJArray()
      if startVal.kind == JInt and endVal.kind == JInt:
        let start = startVal.getInt
        let endNum = endVal.getInt
        if start <= endNum:
          for i in start..endNum:
            result.add(newJInt(i))
        else:
          for i in countdown(start, endNum):
            result.add(newJInt(i))
    
    of nkFilter:
      let value = evaluate(node.arguments[0], context)
      var arguments: seq[JsonNode] = @[]
      for argument in node.arguments[1..^1]:
        arguments.add(evaluate(argument, context))
      result = applyFilter(value, node.filterName, arguments, context)
      if result.kind == JNull:
        result = newJString("")
    
    of nkOperator, nkComparison, nkLogical:
      let left = evaluate(node.left, context)
      let right = evaluate(node.right, context)
      result = applyOperator(node.op, left, right)
      if result.kind == JNull:
        result = newJString("")
    
    of nkTag:
      # Handle specific tags based on tagName
      case node.tagName
      of "if", "unless":
        # For if/unless tags, evaluate the condition from parameters
        if node.parameters.len > 0:
          let conditionValue = evaluate(node.parameters[0], context)
          let conditionMet = 
            if node.tagName == "if":
              # In Liquid, truthy is anything except false and nil
              not (conditionValue.kind == JBool and not conditionValue.getBool) and conditionValue.kind != JNull
            else:  # unless
              # Unless is the opposite of if
              (conditionValue.kind == JBool and not conditionValue.getBool) or conditionValue.kind == JNull
          result = newJBool(conditionMet)
        else:
          result = newJBool(false)
      
      of "assign":
        # Assign tags have two parameters: variable name and value
        if node.parameters.len >= 2:
          let varNode = node.parameters[0]
          let valueNode = node.parameters[1]
          if varNode.kind == nkVariable and varNode.segments.len > 0 and varNode.segments[0].kind == nkString:
            let varName = varNode.segments[0].strVal
            let value = evaluate(valueNode, context)
            context[varName] = value
        result = newJString("")
      
      of "for":
        # For tags need to be handled in the section renderer with body
        result = newJString("")
      
      of "capture":
        # Capture tags need body handling
        result = newJString("")
      
      of "else", "else if":
        # These are handled as part of if/unless blocks
        if node.parameters.len > 0:
          let conditionValue = evaluate(node.parameters[0], context)
          let conditionMet = not (conditionValue.kind == JBool and not conditionValue.getBool) and conditionValue.kind != JNull
          result = newJBool(conditionMet)
        else:
          result = newJBool(true)  # else without condition is always true
      
      else:
        # Other tags return empty string by default
        result = newJString("")
    
    of nkArgument:
      # Arguments evaluate their value
      if not node.argValue.isNil:
        result = evaluate(node.argValue, context)
      else:
        result = newJNull()
    
    of nkEmpty:
      # Empty is a special check - need to evaluate against context
      result = newJBool(true)
    
    of nkEnd, nkContinue:
      # Control flow nodes
      result = newJString("")
      
  except CatchableError as e:
    echo "Error in template evaluation: " & e.msg
    result = newJString("")

proc renderSections*(sections: seq[Section], context: Context): string =
  result = ""
  var i = 0
  
  while i < sections.len:
    let section = sections[i]
    case section.sectionType
    of Text:
      var content = section.content
      # Apply whitespace stripping based on adjacent sections
      if i > 0 and sections[i-1].stripRight:
        # Strip leading whitespace from this text section
        var idx = 0
        while idx < content.len and content[idx] in {' ', '\t', '\n', '\r'}:
          idx += 1
        content = content[idx..^1]
      if i < sections.len - 1 and sections[i+1].stripLeft:
        # Strip trailing whitespace from this text section  
        var idx = content.len - 1
        while idx >= 0 and content[idx] in {' ', '\t', '\n', '\r'}:
          idx -= 1
        content = content[0..idx]
      result &= content
    
    of Output:
      if not section.ast.isNil:
        let evaluated = evaluate(section.ast, context)
        case evaluated.kind
        of JString:
          result &= evaluated.getStr
        of JInt:
          result &= $evaluated.getInt
        of JFloat:
          result &= $evaluated.getFloat
        of JBool:
          result &= $evaluated.getBool
        of JArray:
          # Join array elements
          for j, elem in evaluated.elems:
            if j > 0:
              result &= " "
            case elem.kind
            of JString: result &= elem.getStr
            of JInt: result &= $elem.getInt
            of JFloat: result &= $elem.getFloat
            of JBool: result &= $elem.getBool
            else: discard
        of JNull:
          discard  # Null outputs nothing
        else:
          discard
    
    of Tag:
      if not section.ast.isNil and section.ast.kind == nkTag:
        case section.ast.tagName
        of "if", "unless":
          # Find the matching endif/endunless and process the block
          var j = i + 1
          var depth = 1
          var branches: seq[tuple[condition: Node, startIdx: int, endIdx: int]] = @[]
          var currentBranchStart = i + 1
          var elseBranchStart = -1
          
          # Add the first branch
          branches.add((section.ast.parameters[0], currentBranchStart, -1))
          
          while j < sections.len and depth > 0:
            if sections[j].sectionType == Tag and not sections[j].ast.isNil:
              if sections[j].ast.kind == nkEnd:
                if (section.ast.tagName == "if" and sections[j].ast.tagName == "if") or
                   (section.ast.tagName == "unless" and sections[j].ast.tagName == "unless"):
                  depth -= 1
                  if depth == 0:
                    # Close the last branch
                    if branches.len > 0:
                      branches[^1].endIdx = j
                    if elseBranchStart >= 0:
                      # There was an else branch
                      branches.add((nil, elseBranchStart, j))
              elif sections[j].ast.kind == nkTag:
                case sections[j].ast.tagName
                of "if", "unless":
                  depth += 1
                of "else if":
                  if depth == 1:
                    # Close current branch and start new one
                    branches[^1].endIdx = j
                    if sections[j].ast.parameters.len > 0:
                      branches.add((sections[j].ast.parameters[0], j + 1, -1))
                of "else":
                  if depth == 1 and sections[j].ast.parameters.len == 0:
                    # This is an else without condition
                    branches[^1].endIdx = j
                    elseBranchStart = j + 1
            j += 1
          
          # Evaluate branches and render the first true one
          for branch in branches:
            let conditionMet = 
              if branch.condition.isNil:
                true  # else branch
              else:
                let condValue = evaluate(branch.condition, context)
                if section.ast.tagName == "if":
                  not (condValue.kind == JBool and not condValue.getBool) and condValue.kind != JNull
                else:  # unless
                  (condValue.kind == JBool and not condValue.getBool) or condValue.kind == JNull
            
            if conditionMet:
              # Render this branch
              result &= renderSections(sections[branch.startIdx..<branch.endIdx], context)
              break
          
          i = j - 1  # Skip to end of if block
        
        of "for":
          if section.ast.parameters.len >= 2:
            let varNode = section.ast.parameters[0]
            let iterableNode = section.ast.parameters[1]
            
            if varNode.kind == nkVariable and varNode.segments.len > 0 and varNode.segments[0].kind == nkString:
              let loopVar = varNode.segments[0].strVal
              let iterableValue = evaluate(iterableNode, context)
              
              if iterableValue.kind == JArray:
                # Find endfor
                var j = i + 1
                var depth = 1
                while j < sections.len and depth > 0:
                  if sections[j].sectionType == Tag and not sections[j].ast.isNil:
                    if sections[j].ast.kind == nkTag and sections[j].ast.tagName == "for":
                      depth += 1
                    elif sections[j].ast.kind == nkEnd and sections[j].ast.tagName == "for":
                      depth -= 1
                  j += 1
                
                # Render loop body for each item
                for item in iterableValue:
                  var loopContext = context.copy()
                  loopContext[loopVar] = item
                  result &= renderSections(sections[(i+1)..<(j-1)], loopContext)
                
                i = j - 1  # Skip to end of for block
        
        of "assign":
          # Already handled in evaluate
          discard evaluate(section.ast, context)
        
        of "raw":
          # Raw tag outputs its content literally
          if section.ast.parameters.len > 0 and section.ast.parameters[0].kind == nkString:
            result &= section.ast.parameters[0].strVal
          # Skip to endraw tag
          var j = i + 1
          while j < sections.len:
            if sections[j].sectionType == Tag and sections[j].ast != nil and 
               sections[j].ast.kind == nkEnd and sections[j].ast.tagName == "raw":
              i = j
              break
            j += 1
        
        else:
          # Other tags - just evaluate them
          discard evaluate(section.ast, context)
    
    i += 1

proc renderTemplate*(node: Node, context: Context): string =
  try:
    let evaluated = evaluate(node, context)
    case evaluated.kind
    of JString:
      result = evaluated.getStr
    of JInt:
      result = $evaluated.getInt
    of JFloat:
      result = $evaluated.getFloat
    of JBool:
      result = $evaluated.getBool
    else:
      result = ""
  except CatchableError as e:
    echo "Error in template rendering: " & e.msg
    result = ""
