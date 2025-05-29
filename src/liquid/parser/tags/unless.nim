import ../../types, ../core

const tag_info* = TagHandlerInfo(
  opening_tag: "unless",
  block_tag: true,
  inner_tags: @["elsif", "elif", "elseif", "else"]
)

proc parse*(p: Parser): Node =
  case p.advance().value:
    of "unless":
      result = Node(kind: nkTag, tagName: "unless", parameters: @[p.parseExpression()])
    of "endunless":
      result = Node(kind: nkEnd, tagName: "unless", parameters: @[])
    else:
      result = nil