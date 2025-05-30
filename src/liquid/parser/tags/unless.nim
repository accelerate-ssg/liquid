import ../../types, ../core

const tag_info* = TagHandlerInfo(
  opening_tag: "unless",
  block_tag: true,
  inner_tags: @["elsif", "elif", "elseif", "else"]
)

proc parse*(p: Parser): Node =
  let token = p.advance()
  # Treat elsif variants as keywords for this tag
  var tokenValue = token.value
  if token.kind == TkIdentifier and token.value in ["elsif", "elif", "elseif"]:
    tokenValue = "elsif"  # Normalize all variants
  
  case tokenValue:
    of "unless":
      result = Node(kind: nkTag, tagName: "unless", parameters: @[p.parseExpression()])
    of "elsif":
      result = Node(kind: nkTag, tagName: "else if", parameters: @[p.parseExpression()])
    of "else":
      if p.current.value == "if":
        discard p.advance()
        result = Node(kind: nkTag, tagName: "else if", parameters: @[p.parseExpression()])
      else:
        result = Node(kind: nkTag, tagName: "else", parameters: @[])
    of "endunless":
      result = Node(kind: nkEnd, tagName: "unless", parameters: @[])
    else:
      result = nil