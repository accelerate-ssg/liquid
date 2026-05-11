import ../../types, ../core

const tag_info* = TagHandlerInfo(
  opening_tag: "raw",
  block_tag: true,
  inner_tags: @[]
)

proc parse*(p: Parser): Node =
  case p.advance().value:
    of "raw":
      # Raw tag content will be extracted by the main parser from section content
      result = Node(kind: nkTag, tagName: "raw", parameters: @[])
    of "endraw", "end":
      result = Node(kind: nkEnd, tagName: "raw", parameters: @[])
    else:
      result = nil