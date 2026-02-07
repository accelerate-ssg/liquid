import tables

export toTable

type
  TokenKind* = enum
    # ============ LITERALS ============
    tkIdentifier        # variable names, property access, filter names, custom tags
    tkNumber           # 123, 45.67
    tkString           # "hello" or 'hello'
    tkTrue             # true
    tkFalse            # false
    tkNil              # nil, null
    tkEmpty            # empty
    
    # ============ OPERATORS ============
    # Comparison
    tkEq               # ==
    tkNeq              # !=
    tkLt               # <
    tkLte              # <=
    tkGt               # >
    tkGte              # >=
    
    # Logical
    tkAnd              # and
    tkOr               # or
    tkNot              # not
    tkContains         # contains
    tkIn               # in
    
    # Arithmetic
    tkPlus             # +
    tkMinus            # -
    tkMul              # *
    tkDiv              # /
    tkMod              # % (modulo)
    
    # ============ PUNCTUATION ============
    tkDot              # .
    tkDoubleDot        # .. (range operator)
    tkComma            # ,
    tkColon            # :
    tkPipe             # | (filter separator)
    tkAssign           # = (assignment, not comparison)
    tkQuestion         # ? (for optional chaining/existence)
    
    # ============ BRACKETS ============
    tkLeftParen        # (
    tkRightParen       # )
    tkLeftBracket      # [
    tkRightBracket     # ]
    
    # ============ CORE LIQUID KEYWORDS ============
    # Conditionals
    tkIf               # if
    tkElsif            # elsif, elseif  
    tkElse             # else
    tkEndif            # endif
    tkUnless           # unless
    tkEndunless        # endunless
    tkCase             # case
    tkWhen             # when
    tkEndcase          # endcase
    
    # Loops
    tkFor              # for
    tkEndfor           # endfor
    tkBreak            # break
    tkContinue         # continue
    tkEndtablerow      # endtablerow
    
    # Special blocks
    tkLiquid           # liquid (special multiline liquid tag)
    
    # Variable assignment
    tkAssignTag        # assign (the tag, separate from = operator)
    tkCapture          # capture (captures content into variable)
    tkEndcapture       # endcapture
    
    # ============ SPECIAL TOKENS ============
    tkNewline          # \n (only when preserving newlines in liquid tag)
    tkEOF              # End of file/input

  SectionKind* = enum
    skText             # Plain text or raw block contents
    skOutput           # {{ ... }} sections
    skTag              # {% ... %} sections (non-comment, non-raw)

  Token* = object
    kind*: TokenKind
    start*: int
    stop*: int
  
  Section* = object
    kind*: SectionKind
    start*: int
    stop*: int
    stripLeft*: bool
    stripRight*: bool
    tokens*: seq[Token]

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

  TagInfo* = object
    continuations*: seq[string]
    closure*: string
    required*: seq[string]  # New field for required tags

  TagStackItem* = object
    info*: TagInfo
    hasRequired*: bool  # Track if required tags have been seen

  TagStack* = seq[TagStackItem]

# Pretty printer for debugging
proc debug*(t: Token, input: string = ""): string = 
  result = "(" & $t.kind 
  if input.len >= t.stop:
    result &= ": " & input[t.start..t.stop]
  result &= ")"

proc debug*(s: Section, input: string = ""): string =
  result = "Section(" & $s.kind
  if input.len >= s.stop:
    result &= ", \"" & input[s.start..s.stop] & "\""
  result &= ", pos: " & $s.start & "->" & $s.stop
  if s.stripLeft: result &= ", stripLeft"
  if s.stripRight: result &= ", stripRight"
  if s.tokens.len > 0:
    result &= ", tokens=["
    for i, tok in s.tokens:
      if i > 0: result &= ", "
      result &= tok.debug(input)
    result &= "]"
  result &= ")"

proc debug*(sections: seq[Section], input: string = ""): string =
  for i, s in sections:
    if i > 0: result &= "\n"
    result &= s.debug(input)
