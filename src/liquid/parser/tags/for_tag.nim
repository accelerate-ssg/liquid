include json

include ../core, ../to_string

const tag_info* = TagHandlerInfo(opening_tag: "for", block_tag: true)

proc parse*(p: Parser): Node =
  case p.advance().value:
    of "for":
      let
        identifier = p.advance()
        operator = p.advance()
        value = p.parseExpression()

      echo "Handling for tag"
      echo "Identifier: ", identifier
      echo "Operator: ", operator
      echo "Value: ", $value
        
      if identifier.kind != TkIdentifier and not p.strict_mode:
        raise newException(ValueError, "Expected variable name in for tag")

      if identifier.value[^1] == '?' and p.strict_mode:
        raise newException(ValueError, "For clause variable names cannot end with '?' in strict mode")

      if operator.kind == TkDot:
        raise newException(ValueError, "Variable names cannot contain dots in for tag")

      if operator.kind != TkOperator or operator.value != "in":
        raise newException(ValueError, "Expected 'in' in for tag")

      result = Node(kind: nkTag, tagName: "for", parameters: @[
        Node(kind: nkVariable, segments: @[Node(kind: nkString, strVal: identifier.value)]),
        value
      ])

      while p.current.kind == TkParameter:
        let
          name = p.advance.value
          colon = p.advance()
        var
          value = p.parseExpression()

        if colon.kind != TkColon:
          raise newException(ValueError, "Expected : after parameter name")

        echo "Parameter: ", name, " Value: ", $value

        case name:
          of "limit", "offset":
            if value.kind == nkString and value.strVal != "continue":
              try:
                let floatValue = value.strVal.parseFloat()

                if floatValue == NAN:
                  raise newException(ValueError, "Expected number for parameter: " & name)

                value = Node(kind: nkNumber, numVal: value.strVal.parseFloat())
              except ValueError:
                raise newException(ValueError, "Expected number for parameter: " & name)
            elif value.kind != nkNumber:
              raise newException(ValueError, "Expected number for parameter: " & name)
          else: raise newException(ValueError, "Unknown parameter name: " & name)

        result.parameters.add(Node(kind: nkArgument, argName: name, argValue: value))
        
        if p.current.kind == TkComma: # consume optional comma
          discard p.advance()

    of "endfor","end": result = Node(kind: nkEnd, tagName: "for", parameters: @[])
    else: result = nil

proc evaluate*(node: Node, context: JsonNode): JsonNode =
  JsonNode()
