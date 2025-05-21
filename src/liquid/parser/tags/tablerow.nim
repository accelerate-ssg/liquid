include json

include ../core

const tag_info* = TagHandlerInfo(opening_tag: "tablerow", block_tag: true)

proc parse*(p: Parser): Node =
  case p.advance().value:
    of "tablerow":
      let
        identifier = p.advance()
        operator = p.advance()
        value = p.parseExpression()
        
      if identifier.kind != TkIdentifier and not p.strict_mode:
        raise newException(ValueError, "Expected variable name in tablerow tag")

      if identifier.value[^1] == '?' and p.strict_mode:
        raise newException(ValueError, "Tablerow clause variable names cannot end with '?' in strict mode")

      if operator.kind == TkDot:
        raise newException(ValueError, "Variable names cannot contain dots in tablerow tag")

      if operator.kind != TkOperator or operator.value != "in":
        raise newException(ValueError, "Expected 'in' in tablerow tag")

      result = Node(kind: nkTag, tagName: "tablerow", parameters: @[
        Node(kind: nkVariable, segments: @[Node(kind: nkString, strVal: identifier.value)]),
        value
      ])

      while p.current.kind == TkParameter:
        let
          name = p.advance.value
          colon = p.advance()
          value = p.parseExpression()

        if colon.kind != TkColon:
          raise newException(ValueError, "Expected : after parameter name")

        result.parameters.add(Node(kind: nkArgument, argName: name, argValue: value))

        if p.current.kind == TkComma: # consume optional comma
          discard p.advance()

    of "endtablerow","end": result = Node(kind: nkEnd, tagName: "tablerow", parameters: @[])
    else: result = nil

proc evaluate*(node: Node, context: JsonNode): JsonNode =
  JsonNode()
