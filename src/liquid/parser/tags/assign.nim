import json

import ../../types, ../core

const tag_info* = TagHandlerInfo(opening_tag: "assign", block_tag: false)

proc parse*(p: Parser): Node =
  case p.advance().value:
    of "assign":
      let
        identifier = p.advance()
        assign = p.advance()
        value = p.parseExpression()

      echo "Handling assign tag"

      if identifier.kind != TkIdentifier and not p.strict_mode:
        raise newException(ValueError, "Expected variable name in assign tag")

      if identifier.value[^1] == '?' and p.strict_mode:
        raise newException(ValueError, "Assign clause variable names cannot end with '?' in strict mode")

      if assign.kind == TkDot:
        raise newException(ValueError, "Variable names cannot contain dots in assign tag")

      if assign.kind != TkAssign:
        raise newException(ValueError, "Expected = in assign tag")

      result = Node(kind: nkTag, tagName: "assign", parameters: @[
        Node(kind: nkVariable, segments: @[Node(kind: nkString, strVal: identifier.value)]),
        value
      ])
    else:
      echo "Tag not found, " & p.current().value
      result = nil

proc evaluate*(node: Node, context: JsonNode): JsonNode =
  JsonNode()
