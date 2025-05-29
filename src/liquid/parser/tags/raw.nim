import ../../types, ../core

const tag_info* = TagHandlerInfo(
  opening_tag: "raw",
  block_tag: true,
  inner_tags: @[]
)

proc parse*(p: Parser): Node =
  case p.advance().value:
    of "raw":
      # For now, we create a raw tag node
      # Full implementation requires lexer changes to preserve content literally
      result = Node(kind: nkTag, tagName: "raw", parameters: @[])
    of "endraw", "end":
      result = Node(kind: nkEnd, tagName: "raw", parameters: @[])
    else:
      result = nil