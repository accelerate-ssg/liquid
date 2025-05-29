import ../../types, ../core

const tag_info* = TagHandlerInfo(
  opening_tag: "include",
  block_tag: false,
  inner_tags: @[]
)

proc parse*(p: Parser): Node =
  case p.advance().value:
    of "include":
      # Parse template name
      let templateName = p.parseExpression()
      var parameters: seq[Node] = @[templateName]
      
      # Parse optional parameters
      while p.position < p.tokens.len and p.current().kind != TkEOF and p.current().kind != TkPipe:
        let token = p.current()
        
        # Check for parameter assignment
        if token.kind == TkIdentifier:
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
      
      result = Node(kind: nkTag, tagName: "include", parameters: parameters)
    else:
      result = nil