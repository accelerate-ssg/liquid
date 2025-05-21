import strutils
import ../types, helpers, functions

proc lexToken(l: var Lexer): Token =
  l.skipWhitespace()
  if l.isAtEnd:
    return Token(kind: TkEOF, value: "", startPos: l.position, endPos: l.position)
  
  let c = l.peek
  case c
  of {'a'..'z', 'A'..'Z', '_'}:
    result = l.lexIdentifier()
  of {'0'..'9'}:
    result = l.lexNumber()
  of '"', '\'':
    result = l.lexString()
  of '.':
    result = l.lexOperator('.', '.', TkDot, TkRange)
  of '=':
    result = l.lexOperator('=', '=', TkAssign, TkOperator)
  of '>':
    result = l.lexOperator('>', '=', TkOperator, TkOperator)
  of '<':
    if l.peekNext == '>':
      let start = l.position
      discard l.advance
      discard l.advance
      result = Token(kind: TkOperator, value: "!=", startPos: start, endPos: l.position)
    else:
      result = l.lexOperator('<', '=', TkOperator, TkOperator)
  of '!':
    result = l.lexOperator('!', '=', TkOperator, TkOperator)
  of ',': result = Token(kind: TkComma, value: $l.advance, startPos: l.position, endPos: l.position)
  of ':': result = Token(kind: TkColon, value: $l.advance, startPos: l.position, endPos: l.position)
  of '|': result = Token(kind: TkPipe, value: $l.advance, startPos: l.position, endPos: l.position)
  of '(': result = Token(kind: TkLeftParen, value: $l.advance, startPos: l.position, endPos: l.position)
  of ')': result = Token(kind: TkRightParen, value: $l.advance, startPos: l.position, endPos: l.position)
  of '[': result = Token(kind: TkLeftBracket, value: $l.advance, startPos: l.position, endPos: l.position)
  of ']': result = Token(kind: TkRightBracket, value: $l.advance, startPos: l.position, endPos: l.position)
  of '+', '-', '*', '/', '%':
    if c == '-' and l.peekNext().isDigit():
      # Handle negative numbers
      return l.lexNumber()
    let startPos = l.position
    var value = $l.advance
    if l.peek == '=' or (value in [">", "<"] and l.peek in ['>', '<']):
      value.add(l.advance)
    result = Token(kind: TkOperator, value: value, startPos: startPos, endPos: l.position - 1)
  else:
    raise newException(LexerError, "Unexpected character: " & $c)

proc lexTagSection*(content: string): seq[Token] =
  var lexer = initLexer(content)
  result = @[]
  while not lexer.isAtEnd:
    let token = lexer.lexToken()
    if token.kind == TkEOF: break
    if token.kind != TkKeyword or token.value != "":
      lexer.last = token
      result.add(token)

when isMainModule and not defined(release):
  import unittest
  include ../../../test/lexers/tag
  include ../../../test/lexers/output
