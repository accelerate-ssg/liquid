import json, tables

type
  NodeKind* = enum
    nkOutput, nkEmpty, nkNil, nkVariable, nkString, nkNumber, nkBoolean, nkRange, nkArray, nkOperator, nkFilter, nkArgument, nkComparison, nkLogical, nkTag, nkEnd, nkContinue

  Node* = ref object
    case kind*: NodeKind
    of nkTag, nkEnd, nkContinue:
      tagName*: string
      parameters*: seq[Node]
    of nkOutput:
      children*: seq[Node]
    of nkVariable:
      segments*: seq[Node]
    of nkString:
      strVal*: string
    of nkNumber:
      numVal*: float
    of nkBoolean:
      boolVal*: bool
    of nkRange:
      rangeStart*, rangeEnd*: Node
    of nkArray:
      elements*: seq[Node]
    of nkOperator, nkComparison, nkLogical:
      op*: string
      left*, right*: Node
    of nkFilter:
      filterName*: string
      arguments*: seq[Node]
    of nkArgument:
      argName*: string
      argValue*: Node
    else:
      discard

  TagHandlerInfo* = object
    opening_tag*: string
    block_tag*: bool
    inner_tags*: seq[string]  # Tags that can appear within this block (separators, control flow, etc.)
      
  TagHandler* = proc(parser: Parser): Node

  Parser* = ref object
    tokens*: seq[Token]
    position*: int
    strict_mode*: bool
    tagHandlerLookup*: Table[TagHandlerInfo, TagHandler]
    handlerStack*: seq[TagHandler]
    dynamicKeywords*: seq[string]  # Keywords added from registered tags

  TokenKind* = enum
    TkKeyword, TkIdentifier, TkOperator, TkString, TkNumber,
    TkDot, TkComma, TkColon, TkPipe, TkAssign, TkRange,
    TkLeftParen, TkRightParen, TkLeftBracket, TkRightBracket,
    TkBoolean, TkEmpty, TkNil, TkParameter, TkEOF,
    TkAnd, TkOr, TkSymbol, TkNewline

  Token* = object
    kind*: TokenKind
    value*: string
    startPos*, endPos*, line*, column*: int

  SectionType* = enum
    Text, Output, Tag

  Section* = ref object
    sectionType*: SectionType
    content*: string
    rawContent*: string  # For raw tags, stores the raw content separately
    startRow*, startCol*: int
    endRow*, endCol*: int
    stripLeft*, stripRight*: bool
    tokens*: seq[Token]
    ast*: Node

  SectionLexer* = ref object
    lexer*: Lexer
    inSpecialSection*: bool
    currentSection*: Section
    openBrackets*: int
    sections*: seq[Section]
    inString*: bool
    stringDelimiter*: char

  LexerError* = object of CatchableError

  Lexer* = object
    input*: string
    position*: int
    line*, column*: int
    last*: Token

  TagInfo* = object
    continuations*: seq[string]
    closure*: string
    required*: seq[string]  # New field for required tags

  TagStackItem* = object
    info*: TagInfo
    hasRequired*: bool  # Track if required tags have been seen

  TagStack* = seq[TagStackItem]

const KEYWORDS*: seq[string] = @[]  # No global keywords - all context-specific
