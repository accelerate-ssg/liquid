import strutils

import ../types

proc peek*(p: Parser): Token =
  if p.position >= p.tokens.len - 1:
    return Token(kind: TkEOF)
  p.tokens[p.position + 1]

proc current*(p: Parser): Token =
  if p.position >= p.tokens.len:
    return Token(kind: TkEOF)
  p.tokens[p.position]

proc advance*(p: Parser): Token =
  result = p.current()
  if p.position < p.tokens.len:
    p.position += 1

proc treatAsKeyword*(p: Parser, keywords: openArray[string]): Token =
  ## Convert the current token to a keyword if it matches one of the provided keywords
  result = p.current()
  if result.kind == TkIdentifier and result.value in keywords:
    result.kind = TkKeyword

proc parseExpression*(p: Parser): Node
proc parseLogical*(p: Parser): Node

proc parseArrayAccess(p: Parser): Node =
  if p.current().kind != TkLeftBracket:
    raise newException(ValueError, "Expected [ at start of array access")
  discard p.advance() # consume [
  result = p.parseExpression()
  if p.current().kind != TkRightBracket:
    raise newException(ValueError, "Expected ] at end of array access")
  discard p.advance() # consume ]

proc parseVariable*(p: Parser): Node =
  var segments: seq[Node] = @[]

  let firstToken = p.advance()
  segments.add(Node(kind: nkString, strVal: firstToken.value))
  
  while p.current().kind in [TkDot, TkLeftBracket]:
    if p.current.kind == TkDot:
      discard p.advance()
      # Check if next token is a number (for array access like products.0.title)
      if p.current().kind == TkNumber:
        if p.strict_mode:
          raise newException(ValueError, "Numeric indices after dots are not allowed in strict mode")
        # Convert dot notation with number to bracket notation
        let numToken = p.advance()
        let numVal = parseFloat(numToken.value)
        segments.add(Node(kind: nkNumber, numVal: numVal))
      else:
        let prop = p.advance()
        segments.add(Node(kind: nkString, strVal: prop.value))
    else:
      let prop = p.parseArrayAccess()
      segments.add(prop)
  
  if segments.len == 1 and segments[0].kind == nkString:
    case segments[0].strVal
    of "empty": return Node(kind: nkEmpty)
    of "nil": return Node(kind: nkNil)
    else: discard

  result = Node(kind: nkVariable, segments: segments)

proc parseFilter(p: Parser): Node =
  let filterName = p.advance().value
  var arguments: seq[Node] = @[]
  if p.current.kind == TkColon:
    discard p.advance()  # consume colon
    while true:
      let argName = if p.current().kind == TkIdentifier and p.peek().kind == TkColon:
        let name = p.advance().value
        discard p.advance() # consume colon
        name
      else: ""
      let argValue = p.parseLogical()
      arguments.add(Node(kind: nkArgument, argName: argName, argValue: argValue))
      if p.current().kind != TkComma:
        break
      discard p.advance()  # consume the comma
  Node(kind: nkFilter, filterName: filterName, arguments: arguments)

proc parseRange(p: Parser): Node =
  if p.current().kind != TkLeftParen:
    raise newException(ValueError, "Expected ( at start of range")
  discard p.advance() # consume (

  let rangeStart = p.parseExpression()

  if p.current.kind != TkRange:
    raise newException(ValueError, "Expected .. in range expression")
  discard p.advance() # consume ..

  let rangeEnd = p.parseExpression()

  if p.current.kind != TkRightParen:
    raise newException(ValueError, "Expected ) at end of range")
  discard p.advance() # consume )

  Node(kind: nkRange, rangeStart: rangeStart, rangeEnd: rangeEnd)

proc parseArray(p: Parser): Node =
  var elements: seq[Node] = @[]
  if p.current().kind != TkLeftBracket:
    raise newException(ValueError, "Expected [ at start of array")
  discard p.advance() # consume [

  while p.current().kind != TkRightBracket:
    let value = p.parseExpression()
    elements.add(value)
    if p.current.kind == TkComma:
      discard p.advance() # consume comma
    else:
      if p.current.kind != TkRightBracket:
        raise newException(ValueError, "Expected , or ] at end of array")
      discard p.advance() # consume ]
      break

  Node(kind: nkArray, elements: elements)

proc parseScalar*(p: Parser): Node =
  case p.current().kind
  of TkString:
    result = Node(kind: nkString, strVal: p.advance().value)
  of TkNumber:
    result = Node(kind: nkNumber, numVal: parseFloat(p.advance().value))
  of TkBoolean:
    result = Node(kind: nkBoolean, boolVal: parseBool(p.advance().value))
  of TkIdentifier:
    result = p.parseVariable()
  of TkLeftParen:
    result = p.parseRange()
  of TkLeftBracket:
    # Check if this is bracket notation [something] or array literal [1,2,3]
    let savedPos = p.position
    discard p.advance() # consume [
    
    # Try to parse as bracket notation first
    var isBracketNotation = false
    
    # Look ahead to determine if this is bracket notation or array literal
    # Bracket notation: [expr] where expr is not followed by comma
    # Array literal: [expr, expr, ...] or []
    if p.current().kind == TkRightBracket:
      # Empty array []
      p.position = savedPos
      result = p.parseArray()
    else:
      # Parse the first expression
      let index = p.parseExpression()
      
      # Check what follows
      if p.current().kind == TkRightBracket:
        # This is bracket notation [expr]
        discard p.advance() # consume ]
        
        # Create index with nil base
        var segments: seq[Node] = @[Node(kind: nkNil), index]
        result = Node(kind: nkVariable, segments: segments)
        
        # Check for chained access like [something].foo or [something][bar] or [something]foo
        while p.current().kind in [TkDot, TkLeftBracket, TkIdentifier]:
          if p.current.kind == TkDot:
            discard p.advance()
            let prop = p.advance()
            segments.add(Node(kind: nkString, strVal: prop.value))
          elif p.current.kind == TkLeftBracket:
            let prop = p.parseArrayAccess()
            segments.add(prop)
          else:
            # Handle identifier directly after bracket without dot
            let prop = p.advance()
            segments.add(Node(kind: nkString, strVal: prop.value))
        
        result.segments = segments
      elif p.current().kind == TkComma:
        # This is an array literal [expr, ...]
        p.position = savedPos
        result = p.parseArray()
      else:
        raise newException(ValueError, "Expected ] or , in bracket expression")
  of TkNil, TkEOF:
    discard p.advance()
    result = Node(kind: nkNil)
  of TkEmpty:
    discard p.advance()
    result = Node(kind: nkEmpty)
  of TkKeyword:
    if p.current().value == "continue":
      discard p.advance()
      result = Node(kind: nkContinue)
    else:
      # Treat keywords as identifiers when we get here
      result = p.parseVariable()
  else:
    raise newException(ValueError, "Unexpected token: " & $p.current().kind)

proc parseComparison(p: Parser): Node =
  result = p.parseScalar()
  while true:
    if p.current.kind == TkOperator:
      var
        op = p.advance.value
      let
        right = p.parseScalar()

      if op == "<>": op = "!="

      result = Node(kind: nkComparison, op: op, left: result, right: right)
    else:
      break

proc parseLogical(p: Parser): Node =
  result = p.parseComparison()
  while p.current.kind in [TkAnd, TkOr]:
    discard p.advance() # consume and/or
    let op = p.tokens[p.position - 1].value
    let right = p.parseComparison()
    result = Node(kind: nkLogical, op: op, left: result, right: right)

proc parseExpression*(p: Parser): Node =
  result = p.parseLogical()
  while p.current.kind == TkPipe:
    discard p.advance() # consume pipe
    let filter = p.parseFilter()
    filter.arguments.insert(result, 0)
    result = filter

