include json

include ../core

const tag_info* = TagHandlerInfo(opening_tag: "case", block_tag: true)

proc parse*(p: Parser): Node =
  case p.advance().value:
    of "case":
      result = Node(kind: nkTag, tagName: "case", parameters: @[p.parseExpression()])
    of "when":
      var
        parameters: seq[Node] = @[p.parseScalar()]

      while p.current.kind in [TkComma, TkOr]:
        discard p.advance() # consume comma or or
        parameters.add(p.parseScalar())

      if parameters.len == 0 or parameters[0].kind == nkNil:
        raise newException(ValueError, "Expected at least one condition in when tag")
      else:
        result = Node(kind: nkTag, tagName: "when", parameters: parameters)
    of "else":
      result = Node(kind: nkTag, tagName: "else", parameters: @[])
    of "endcase","end": result = Node(kind: nkEnd, tagName: "case", parameters: @[])
    else: result = nil

proc evaluate*(node: Node, context: JsonNode): JsonNode =
  JsonNode()
