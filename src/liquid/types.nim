type
  TokenKind* = enum WHITESPACE_CONTROL, FILTER, IDENTIFIER, PIPE, COLON, COMMA, STRING_LITERAL, INTEGER_LITERAL, FLOAT_LITERAL, UNKNOWN
    
  Token* = object
    case kind*: TokenKind
      of IDENTIFIER: identifier_name*: string
      of FILTER: filter_name*: string
      of STRING_LITERAL: string_value*: string
      of INTEGER_LITERAL: integer_value*: int
      of FLOAT_LITERAL: float_value*: float
      of UNKNOWN: match*: string
      else: discard
    content*: string
    

  MetaTokenKind* = enum VARIABLE, TAG, TEXT
  MetaToken* = object
    case kind*: MetaTokenKind
      of VARIABLE,TAG: tokens*: seq[TOKEN]
      else: discard
    start_pos*, end_pos*: int
    result*: string

