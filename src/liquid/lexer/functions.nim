import strutils

import ../types, helpers

template lexOperator*(l: var Lexer, singleChar: char, doubleChar: char, 
                                 singleKind, doubleKind: TokenKind): Token =
  let startPos = l.position
  discard l.advance
  if l.peek == doubleChar:
    discard l.advance
    Token(kind: doubleKind, value: $singleChar & $doubleChar, startPos: startPos, endPos: l.position - 1)
  else:
    Token(kind: singleKind, value: $singleChar, startPos: startPos, endPos: startPos)


proc lexIdentifier*(l: var Lexer): Token =
  let
    startPos = l.position
  
  while not l.isAtEnd and (isAlphaNumeric(l.peek) or l.peek == '_' or l.peek == '-'):
    discard l.advance
  if not l.isAtEnd and l.peek == '?':
    discard l.advance
  
  let value = l.input[startPos..<l.position]
  let kind = if value in KEYWORDS:
    TkKeyword
  elif value in ["true", "false"]:
    TkBoolean
  elif value in ["nil", "null"]:
    TkNil
  elif value == "empty":
    TkEmpty
  elif value in ["contains", "in", "not"]:
    TkOperator
  elif value == "or":
    TkOr
  elif value == "and":
    TkAnd
  elif value in ["with", "reversed"] or (l.peek == ':' and l.last.kind != TkPipe):
    TkParameter
  else:
    TkIdentifier
  
  Token(kind: kind, value: value, startPos: startPos, endPos: l.position - 1)

proc lexNumber*(l: var Lexer): Token =
  let startPos = l.position
  if l.peek == '-':
    discard l.advance
  
  while not l.isAtEnd and isDigit(l.peek):
    discard l.advance
  
  if l.peek == '.' and isDigit(l.peekNext):
    discard l.advance
    while not l.isAtEnd and isDigit(l.peek):
      discard l.advance
  


  Token(kind: TkNumber, value: l.input[startPos..<l.position],
           startPos: startPos, endPos: l.position - 1)

proc lexString*(l: var Lexer): Token =
  let startPos = l.position
  let quote = l.advance
  var value = ""
  while not l.isAtEnd and l.peek != quote:
    if l.peek == '\\' and l.peekNext == quote:
      discard l.advance
    value.add(l.advance)
  
  if l.isAtEnd:
    raise newException(LexerError, "Unterminated string.")
  
  discard l.advance  # Closing quote
  Token(kind: TkString, value: value, startPos: startPos, endPos: l.position - 1)
