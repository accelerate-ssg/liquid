include json

include ../core, ../to_string

const tag_info* = TagHandlerInfo(
  opening_tag: "for",
  block_tag: true,
  inner_tags: @["else", "break", "continue"]  # For loop can have else clause and control flow
)

proc parse*(p: Parser): Node =
  case p.advance().value:
    of "for":
      let
        identifier = p.advance()
        operator = p.advance()
        value = p.parseExpression()

# Debug: removed echo statements
        
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

      # Check for bare 'reversed' identifier and treat as keyword
      if p.current.kind == TkIdentifier and p.current.value == "reversed":
        discard p.advance()  # consume 'reversed'
        result.parameters.add(Node(kind: nkArgument, argName: "reversed", argValue: Node(kind: nkBoolean, boolVal: true)))

      while p.current.kind == TkIdentifier and p.peek.kind == TkColon:
        let
          name = p.advance.value
          colon = p.advance()
        var
          value = p.parseExpression()

        if colon.kind != TkColon:
          raise newException(ValueError, "Expected : after parameter name")

# Debug: removed echo statement

        case name:
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
              raise newException(ValueError, "Expected number for parameter: " & name)
          of "reversed":
            if value.kind != nkBoolean:
              raise newException(ValueError, "Expected boolean for reversed parameter")
          else: raise newException(ValueError, "Unknown parameter name: " & name)

        result.parameters.add(Node(kind: nkArgument, argName: name, argValue: value))
        
        if p.current.kind == TkComma: # consume optional comma
          discard p.advance()

    of "else":
      result = Node(kind: nkTag, tagName: "else", parameters: @[])
    of "break":
      result = Node(kind: nkContinue, tagName: "break", parameters: @[])  # Using nkContinue for control flow
    of "continue":
      result = Node(kind: nkContinue, tagName: "continue", parameters: @[])
    of "endfor","end": result = Node(kind: nkEnd, tagName: "for", parameters: @[])
    else: result = nil

proc evaluate*(node: Node, context: JsonNode): JsonNode =
  JsonNode()
