include json

include ../core

const tag_info* = TagHandlerInfo(
  opening_tag: "cycle",
  block_tag: false,
  inner_tags: @[]
)

proc parse*(p: Parser): Node =
  case p.advance().value:
    of "cycle":
      var
        group_name: string = "cycle"
      
      if p.current.kind in [TkIdentifier, TkString] and p.peek.kind == TkColon:
        group_name = p.advance.value
        discard p.advance() # consume colon

      let
        parameters = @[
          Node(kind: nkVariable, segments: @[Node(kind: nkString, strVal: group_name)]),
          Node(kind: nkArray, elements: @[])
        ]
      
      while true:
        parameters[^1].elements.add(p.parseExpression())
        if not (p.current.kind in [TkComma, TkOr]):
          break
        discard p.advance() # consume comma or or
      
      result = Node(kind: nkTag, tagName: "cycle", parameters: parameters) 
    else: result = nil

proc evaluate*(node: Node, context: JsonNode): JsonNode =
  JsonNode()
