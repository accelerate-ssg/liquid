include json

include ../core

const tag_info* = TagHandlerInfo(opening_tag: "echo", block_tag: false)

proc parse*(p: Parser): Node =
  case p.advance().value:
    of "echo": result = Node(kind: nkTag, tagName: "echo", parameters: @[p.parseExpression()])
    else: result = nil

proc evaluate*(node: Node, context: JsonNode): JsonNode =
  JsonNode()
