import ../../types, ../core, strutils

# Parse a variable expression but stop if we encounter "as" keyword
proc parseVariableWithAsContext(p: Parser): Node =
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
    else: # TkLeftBracket
      discard p.advance() # consume [
      let prop = p.parseExpression()
      segments.add(prop)
      if p.current().kind != TkRightBracket:
        raise newException(ValueError, "Expected ] at end of array access")
      discard p.advance() # consume ]
      # After bracket access, check if there's an identifier following
      # BUT STOP if it's the "as" keyword
      if p.current().kind == TkIdentifier and p.current().value != "as":
        let prop = p.advance()
        segments.add(Node(kind: nkString, strVal: prop.value))
  
  result = Node(kind: nkVariable, segments: segments)

const tag_info* = TagHandlerInfo(
  opening_tag: "render",
  block_tag: false,
  inner_tags: @[]
)

proc parse*(p: Parser): Node =
  case p.advance().value:
    of "render":
      # Parse template name
      let templateName = p.parseExpression()
      var parameters: seq[Node] = @[templateName]
      
      # Check for comma after template name
      if p.current().kind == TkComma:
        discard p.advance()  # skip comma
        
        # Parse keyword arguments like "product: product"
        while p.position < p.tokens.len and p.current().kind == TkIdentifier:
          let paramName = p.advance().value
          if p.current().kind == TkColon:
            discard p.advance()  # skip colon
            let value = p.parseExpression()
            # Add key and value as separate parameters (matches nodeRender helper)
            parameters.add(Node(kind: nkVariable, segments: @[Node(kind: nkString, strVal: paramName)]))
            parameters.add(value)
            
            # Skip comma if present
            if p.current().kind == TkComma:
              discard p.advance()
            else:
              break
          else:
            break
      
      # Check for special keywords (with, for, as)
      while p.position < p.tokens.len and p.current().kind != TkEOF and p.current().kind != TkPipe:
        let token = p.current()
        
        if token.kind == TkIdentifier:
          case token.value:
          of "with":
            discard p.advance()
            # Parse expression but be aware of "as" keyword
            let value = p.parseVariableWithAsContext()
            parameters.add(value)  # Add bound variable directly
            
            # Check for "as" clause
            if p.current().kind == TkIdentifier and p.current().value == "as":
              discard p.advance()  # skip "as"
              if p.current().kind == TkIdentifier:
                let asName = p.advance().value
                parameters.add(Node(kind: nkString, strVal: asName))
          of "for":
            discard p.advance()
            let value = p.parseExpression()
            parameters.add(value)  # Add collection directly
          else:
            break
        else:
          break
      
      result = Node(kind: nkTag, tagName: "render", parameters: parameters)
    else:
      result = nil