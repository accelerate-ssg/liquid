import ../../types, ../core

const tag_info* = TagHandlerInfo(
  opening_tag: "#",
  block_tag: false,
  inner_tags: @[]
)

proc parse*(p: Parser): Node =
  # Skip the # symbol
  if p.current.kind == TkSymbol and p.current.value == "#":
    discard p.advance()
  
  # Consume all tokens until EOF - this is a comment so we ignore everything
  while p.current().kind != TkEOF:
    discard p.advance()
  
  # Return a comment node
  result = Node(kind: nkTag, tagName: "#", parameters: @[])