include json

include ../core

const tag_info* = TagHandlerInfo(
  opening_tag: "decrement",
  block_tag: false,
  inner_tags: @[]
)

proc parse*(p: Parser): Node =
  case p.advance().value:
    of "decrement": result = Node(kind: nkTag, tagName: "decrement", parameters: @[p.parseVariable()])
    else: result = nil

proc evaluate*(node: Node, context: JsonNode): JsonNode =
  JsonNode()
