import bridge/c_types
import liquid/types

proc registerCustomTagSet(handler: CTagHandler, tags: openArray[string]) =
  let tagSet = CustomTagSet(handler: handler, tags: @tags)
  customTagSets.add(tagSet)
  for tag in tags:
    tagHandlerLookup[tag] = handler

proc wrapCTagHandler(cHandler: CTagHandler): proc(p: var Parser): Node =
  return proc(p: var Parser): Node =
    let cParser = parserToCParserPtr(p)
    var methods = CParserMethods(
      parseExpression: proc(parser: CParserPtr): CNodePtr {.cdecl.} =
        let nimParser = cParserPtrToParser(parser)
        nodeToCNodePtr(nimParser.parseExpression()),
      advance: proc(parser: CParserPtr): CTokenPtr {.cdecl.} =
        let nimParser = cParserPtrToParser(parser)
        tokenToCTokenPtr(nimParser.advance()),
      current: proc(parser: CParserPtr): CTokenPtr {.cdecl.} =
        let nimParser = cParserPtrToParser(parser)
        tokenToCTokenPtr(nimParser.current())
      # Add other method conversions here
    )
    let ctx = createCTagContext(p)
    let cNode = cHandler(ctx, cParser, addr methods)
    result = cNodePtrToNode(cNode)

    # If the custom tag didn't return a node, create a default nkCustomTag node
    if result.isNil:
      var arguments: seq[Node] = @[]
      while p.current().kind != TkEOF and p.current().kind != TkRightBrace:
        arguments.add(p.parseExpression())
        discard p.advanceIfMatch(TkComma)
      result = Node(kind: nkCustomTag, tagName: p.current().value, arguments: arguments)

proc parseTagSection(p: var Parser): Node =
  let tagName = p.current().value
  if tagName in tagHandlerLookup:
    let handler = wrapCTagHandler(tagHandlerLookup[tagName])
    return handler(p)
  
  # If no custom handler found, create a default nkCustomTag node
  var arguments: seq[Node] = @[]
  while p.current().kind != TkEOF and p.current().kind != TkRightBrace:
    arguments.add(p.parseExpression())
    discard p.advanceIfMatch(TkComma)
  return Node(kind: nkCustomTag, tagName: tagName, arguments: arguments)

# Example usage remains the same
proc myCustomTagHandler(ctx: CTagContext, parser: CParserPtr, methods: ptr CParserMethods): CNodePtr {.cdecl.} =
  # ... (same as before)

# Register the custom tag set
registerCustomTagSet(myCustomTagHandler, ["if", "elsif", "else", "endif"])
