import ../../types, ../core

const tag_info* = TagHandlerInfo(
  opening_tag: "ifchanged",
  block_tag: true,
  inner_tags: @["else"]
)

proc parse*(p: Parser): Node =
  case p.advance().value:
    of "ifchanged":
      # Optional expression to track
      if p.current().kind != TkEOF and p.current().kind != TkPipe and
         p.current().kind != TkKeyword:
        result = Node(kind: nkTag, tagName: "ifchanged", parameters: @[p.parseExpression()])
      else:
        result = Node(kind: nkTag, tagName: "ifchanged", parameters: @[])
    of "else":
      result = Node(kind: nkTag, tagName: "else", parameters: @[])
    of "endifchanged":
      result = Node(kind: nkEnd, tagName: "ifchanged", parameters: @[])
    else:
      result = nil