include json

include ../core

const tag_info* = TagHandlerInfo(
  opening_tag: "tablerow",
  block_tag: true,
  inner_tags: @["break", "continue"]  # Tablerow supports break/continue
)

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

      # Check for comma after expression
      if p.current.kind == TkComma:
        discard p.advance()  # consume comma

      while p.current.kind == TkIdentifier and p.peek.kind == TkColon:
        let
          name = p.advance.value
          colon = p.advance()
        var
          value = p.parseExpression()

        if colon.kind != TkColon:
          raise newException(ValueError, "Expected : after parameter name")

        case name:
          of "cols":
            # cols can be a number or string that converts to number
            if value.kind == nkString:
              # Try to parse string as number
              try:
                let floatValue = value.strVal.parseFloat()
                if floatValue == NAN:
                  raise newException(ValueError, "Expected number for cols parameter")
                value = Node(kind: nkNumber, numVal: floatValue)
              except ValueError:
                # Keep as string - will be converted at runtime
                discard
            elif value.kind != nkNumber:
              # Allow variables and other expressions that will be evaluated at runtime
              discard
          of "limit", "offset":
            if value.kind == nkVariable and value.segments.len == 1 and value.segments[0].kind == nkString and value.segments[0].strVal == "continue" and name == "offset":
              # Special case: offset:continue is allowed
              value = Node(kind: nkContinue)
            elif value.kind == nkString:
              # Try to parse as number
              try:
                let floatValue = value.strVal.parseFloat()
                if floatValue == NAN:
                  raise newException(ValueError, "Expected number for parameter: " & name)
                value = Node(kind: nkNumber, numVal: floatValue)
              except ValueError:
                raise newException(ValueError, "Expected number for parameter: " & name)
            elif value.kind != nkNumber:
              # Allow variables and expressions for dynamic values
              discard
          else: 
            raise newException(ValueError, "Unknown tablerow parameter: " & name)

        result.parameters.add(Node(kind: nkArgument, argName: name, argValue: value))

        if p.current.kind == TkComma: # consume optional comma
          discard p.advance()

    of "break":
      result = Node(kind: nkContinue, tagName: "break", parameters: @[])
    of "continue":
      result = Node(kind: nkContinue, tagName: "continue", parameters: @[])
    of "endtablerow","end": result = Node(kind: nkEnd, tagName: "tablerow", parameters: @[])
    else: result = nil

proc evaluate*(node: Node, context: JsonNode): JsonNode =
  JsonNode()
