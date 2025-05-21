include json

include ../core

const tag_info* = TagHandlerInfo(opening_tag: "if", block_tag: true)

proc parse*(p: Parser): Node =
  case p.advance().value:
    of "if": result = Node(kind: nkTag, tagName: "if", parameters: @[p.parseExpression()])
    of "unless": result = Node(kind: nkTag, tagName: "unless", parameters: @[p.parseExpression()])
    of "elsif", "elif", "elseif": result = Node(kind: nkTag, tagName: "else if", parameters: @[p.parseExpression()])
    of "else":
      if p.current.value == "if":
        discard p.advance()
        result = Node(kind: nkTag, tagName: "else if", parameters: @[p.parseExpression()])
      else:
        result = Node(kind: nkTag, tagName: "else", parameters: @[])
    of "endif","end": result = Node(kind: nkEnd, tagName: "if", parameters: @[])
    else: result = nil

proc evaluate*(node: Node, context: JsonNode): JsonNode =
  JsonNode()
