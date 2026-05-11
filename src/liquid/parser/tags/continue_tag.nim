import ../../types, ../core

const tag_info* = TagHandlerInfo(
  opening_tag: "continue",
  block_tag: false,
  inner_tags: @[]
)

proc parse*(p: Parser): Node =
  case p.advance().value:
    of "continue":
      result = Node(kind: nkContinue)
    else:
      result = nil