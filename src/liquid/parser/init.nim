import tables

import ../types, tags/[assign, capture, case_tag, cycle, decrement, echo_tag, for_tag, if_tag, increment, tablerow]

proc registerTag(parser: Parser, handler: TagHandler, info: TagHandlerInfo) =
  if info in parser.tagHandlerLookup:
    raise newException(ValueError, "Tag already registered: " & info.opening_tag)
  parser.tagHandlerLookup[info] = handler

proc registerDefaultTags*(parser: Parser) =
  parser.registerTag(assign.parse, assign.tag_info)
  parser.registerTag(capture.parse, capture.tag_info)
  parser.registerTag(case_tag.parse, case_tag.tag_info)
  parser.registerTag(cycle.parse, cycle.tag_info)
  parser.registerTag(decrement.parse, decrement.tag_info)
  parser.registerTag(echo_tag.parse, echo_tag.tag_info)
  parser.registerTag(for_tag.parse, for_tag.tag_info)
  parser.registerTag(if_tag.parse, if_tag.tag_info)
  parser.registerTag(increment.parse, increment.tag_info)
  parser.registerTag(tablerow.parse, tablerow.tag_info)

  echo "Registered default tags:"
  for tag in parser.tagHandlerLookup.keys:
    echo "  " & tag.opening_tag

proc initParser*(tokens: seq[Token]): types.Parser =
  result = Parser(tokens: tokens, position: 0, strict_mode: false)
  result.registerDefaultTags()
