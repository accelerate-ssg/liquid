import tables

type
  CTagContext = pointer
  CNodePtr = pointer
  CParserPtr = pointer

  CParseExpressionFunc = proc(parser: CParserPtr): CNodePtr {.cdecl.}
  CAdvanceFunc = proc(parser: CParserPtr): CTokenPtr {.cdecl.}
  CCurrentFunc = proc(parser: CParserPtr): CTokenPtr {.cdecl.}

  CParserMethods = object
    parseExpression: CParseExpressionFunc
    advance: CAdvanceFunc
    current: CCurrentFunc
    # Add other necessary parser methods here

  CTagHandler = proc(ctx: CTagContext, parser: CParserPtr, methods: ptr CParserMethods): CNodePtr {.cdecl.}

  CustomTagSet = object
    handler: CTagHandler
    tags: seq[string]

var 
  customTagSets*: seq[CustomTagSet]
  tagHandlerLookup*: Table[string, CTagHandler]
