import ../../types, ../core

const tag_info* = TagHandlerInfo(
  opening_tag: "break",
  block_tag: false,
  inner_tags: @[]
)

proc parse*(p: Parser): Node =
  case p.advance().value:
    of "break":
      result = Node(kind: nkTag, tagName: "break", parameters: @[])
    else:
      result = nil