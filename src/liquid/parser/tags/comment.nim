import ../../types, ../core

const tag_info* = TagHandlerInfo(
  opening_tag: "comment",
  block_tag: true,
  inner_tags: @[]
)

proc parse*(p: Parser): Node =
  case p.advance().value:
    of "comment":
      result = Node(kind: nkTag, tagName: "comment", parameters: @[])
    of "endcomment":
      result = Node(kind: nkEnd, tagName: "comment", parameters: @[])
    else:
      result = nil