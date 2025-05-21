include json

include ../core

const tag_info* = TagHandlerInfo(opening_tag: "capture", block_tag: true)

proc parse*(p: Parser): Node =
  case p.advance().value:
    of "capture": result = Node(kind: nkTag, tagName: "capture", parameters: @[p.parseVariable()])
    of "endcapture","end": result = Node(kind: nkEnd, tagName: "capture", parameters: @[])
    else: result = nil

proc evaluate*(node: Node, context: JsonNode): JsonNode =
  JsonNode()
