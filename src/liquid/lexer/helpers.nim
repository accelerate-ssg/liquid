import sequtils, strutils

import ../types

proc initLexer*(input: string): Lexer =
  Lexer(input: input, position: 0, line: 1, column: 0)

proc isAtEnd*(l: Lexer): bool =
  l.position >= l.input.len

proc advance*(l: var Lexer): char =
  if l.isAtEnd: return '\0'
  result = l.input[l.position]
  l.position += 1
  if result == '\n':
    l.line += 1
    l.column = 1
  else:
    l.column += 1

proc peek*(l: Lexer): char =
  if l.isAtEnd: '\0'
  else: l.input[l.position]

proc peekNext*(l: Lexer): char =
  if l.position + 1 >= l.input.len: '\0'
  else: l.input[l.position + 1]

proc skipWhitespace*(l: var Lexer) =
  while not l.isAtEnd:
    case l.peek
    of ' ', '\t', '\r', '\n':
      discard l.advance
    else: break

proc `$`*(token: Token): string =
  "<" & $token.kind & ": " & token.value & ">"

proc `$`*(tokens: seq[Token]): string =
  tokens.mapIt($it).join("\n")
