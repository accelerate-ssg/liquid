import tables

import ../types
import tags/[assign, break_tag, capture, case_tag, comment, comment_tag, continue_tag, cycle, decrement, echo_tag, for_tag, if_tag, ifchanged, include_tag, increment, liquid, raw, render, tablerow, unless]

proc registerTag(parser: Parser, handler: TagHandler, info: TagHandlerInfo) =
  if info in parser.tagHandlerLookup:
    raise newException(ValueError, "Tag already registered: " & info.opening_tag)
  parser.tagHandlerLookup[info] = handler
  
  # Add tag keywords dynamically
  if info.opening_tag notin parser.dynamicKeywords:
    parser.dynamicKeywords.add(info.opening_tag)
  
  # Add inner tags as keywords
  for separator in info.inner_tags:
    if separator notin parser.dynamicKeywords:
      parser.dynamicKeywords.add(separator)
  
  # Add end tag variants
  let endTag = "end" & info.opening_tag
  if endTag notin parser.dynamicKeywords:
    parser.dynamicKeywords.add(endTag)

proc registerDefaultTags*(parser: Parser) =
  parser.registerTag(assign.parse, assign.tag_info)
  parser.registerTag(break_tag.parse, break_tag.tag_info)
  parser.registerTag(capture.parse, capture.tag_info)
  parser.registerTag(case_tag.parse, case_tag.tag_info)
  parser.registerTag(comment.parse, comment.tag_info)
  parser.registerTag(comment_tag.parse, comment_tag.tag_info)
  parser.registerTag(continue_tag.parse, continue_tag.tag_info)
  parser.registerTag(cycle.parse, cycle.tag_info)
  parser.registerTag(decrement.parse, decrement.tag_info)
  parser.registerTag(echo_tag.parse, echo_tag.tag_info)
  parser.registerTag(for_tag.parse, for_tag.tag_info)
  parser.registerTag(if_tag.parse, if_tag.tag_info)
  parser.registerTag(ifchanged.parse, ifchanged.tag_info)
  parser.registerTag(include_tag.parse, include_tag.tag_info)
  parser.registerTag(increment.parse, increment.tag_info)
  parser.registerTag(liquid.parse, liquid.tag_info)
  parser.registerTag(raw.parse, raw.tag_info)
  parser.registerTag(render.parse, render.tag_info)
  parser.registerTag(tablerow.parse, tablerow.tag_info)
  parser.registerTag(unless.parse, unless.tag_info)

  echo "Registered default tags:"
  for tag in parser.tagHandlerLookup.keys:
    echo "  " & tag.opening_tag

proc initParser*(tokens: seq[Token]): types.Parser =
  result = Parser(
    tokens: tokens, 
    position: 0, 
    strict_mode: false,
    tagHandlerLookup: initTable[TagHandlerInfo, TagHandler](),
    handlerStack: @[],
    dynamicKeywords: @[]
  )
  result.registerDefaultTags()
