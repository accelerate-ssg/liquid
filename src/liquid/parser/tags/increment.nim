include json

include ../core

const tag_info* = TagHandlerInfo(opening_tag: "increment", block_tag: false)

proc parse*(p: Parser): Node =
  case p.advance().value:
    of "increment": result = Node(kind: nkTag, tagName: "increment", parameters: @[p.parseVariable()])
    else: result = nil

proc evaluate*(node: Node, context: JsonNode): JsonNode =
  JsonNode()
