import ../../types, ../core

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
      
      # Parse optional parameters
      while p.position < p.tokens.len and p.current().kind != TkEOF and p.current().kind != TkPipe:
        let token = p.current()
        
        # Check for special keywords (including identifiers that should be treated as keywords)
        var tokenToCheck = token
        if token.kind == TkIdentifier and token.value in ["with", "as", "for"]:
          tokenToCheck.kind = TkKeyword  # Treat as keyword for this context
        
        if tokenToCheck.kind == TkKeyword:
          case tokenToCheck.value:
          of "with":
            discard p.advance()
            let value = p.parseExpression()
            parameters.add(Node(kind: nkArgument, argName: "with", argValue: value))
          of "for":
            discard p.advance()
            let value = p.parseExpression()
            parameters.add(Node(kind: nkArgument, argName: "for", argValue: value))
          of "as":
            discard p.advance()
            if p.current().kind == TkIdentifier:
              let asName = p.advance().value
              parameters.add(Node(kind: nkArgument, argName: "as", 
                                argValue: Node(kind: nkString, strVal: asName)))
          else:
            break
        # Check for parameter assignment
        elif token.kind == TkIdentifier:
          let paramName = token.value
          if p.peek().kind == TkColon or p.peek().kind == TkAssign:
            discard p.advance()  # skip identifier
            discard p.advance()  # skip : or =
            let value = p.parseExpression()
            parameters.add(Node(kind: nkArgument, argName: paramName, argValue: value))
          else:
            break
        else:
          break
      
      result = Node(kind: nkTag, tagName: "render", parameters: parameters)
    else:
      result = nil