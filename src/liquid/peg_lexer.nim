import pegs, tables, strutils
import lexer/[types, sections]

let liquidGrammar = peg"""
  Tokens   <- (Token / Whitespace)*
  Token    <- Number / String / Filter / Parameter / Identifier / Operator / ArithmeticOperator / Symbol
  Ident    <- \ident (\ident / '-')* # Base form of an identifier in Liquid
  Number   <- '-'? \d+ ('.' \d+)?
  String   <- '"' (!'"' .)* '"' / "'" (!"'" .)* "'"
  Filter   <- '|' \s* Ident
  Parameter <- Ident \s* &':'
  Identifier <- Ident '?'?
  Operator <- "==" / "!=" / "<>" / ">=" / "<=" / ">" / "<" / "=" / "contains"
  ArithmeticOperator <- '+' / '-' / '*' / '/' / '%'
  Symbol   <- ".." / "." / "," / ":" / "|" / "(" / ")" / "[" / "]"
  Whitespace <- (\s / ",")+
"""

proc lexLiquid*(input: string): seq[Token] =
  var 
    tokens: seq[Token] = @[]
    currentToken: Token
    line = 1
    column = 0
    position = 0

  proc updateLineColumn(str: string) =
    for c in str:
      if c == '\n':
        line += 1
        column = 0
      else:
        column += 1

  let parse = liquidGrammar.eventParser:
    pkNonTerminal:
      enter:
        case p.nt.name
        of "Number", "String", "Identifier", "Operator", "Symbol":
          currentToken = Token(kind: TkEOF, startPos: start, line: line, column: column)
      leave:
        if length > 0:
          let matchStr = s.substr(start, start+length-1)
          case p.nt.name
          of "Number":
            currentToken.kind = TkNumber
            currentToken.value = matchStr
          of "String":
            currentToken.kind = TkString
            currentToken.value = matchStr[1..^2]
          of "Filter":
            tokens.add(
              Token(kind: TkPipe, value: "|", startPos: start, endPos: start + 1, line: line, column: column)
            )
            currentToken.kind = TkIdentifier
            currentToken.value = matchStr[1..^1].strip()
            currentToken.startPos = start + matchStr.len - currentToken.value.len
          of "Parameter":
            currentToken.kind = TkParameter
            currentToken.value = matchStr
          of "Identifier":
            currentToken.kind = 
              if matchStr in KEYWORDS:
                TkKeyword
              elif matchStr in ["true", "false"]:
                TkBoolean
              elif matchStr in ["nil", "null"]:
                TkNil
              elif matchStr == "empty":
                TkEmpty
              elif matchStr == "contains":
                TkContains
              elif matchStr == "or":
                TkOr
              elif matchStr == "and":
                TkAnd
              elif matchStr == "not":
                TkOperator
              elif matchStr in ["with", "offset", "limit", "reversed"]:
                TkParameter
              else:
                TkIdentifier
            currentToken.value = matchStr
          of "Operator":
            if matchStr == "=":
              currentToken.kind = TkAssign
            elif matchStr == "contains":
              currentToken.kind = TkContains
            else:
              currentToken.kind = TkOperator
            currentToken.value = matchStr
          of "ArithmeticOperator":
            currentToken.kind = TkOperator
            currentToken.value = matchStr
          of "Symbol":
            currentToken.kind = case matchStr
              of "..": TkRange
              of ".": TkDot
              of ",": TkComma
              of ":": TkColon
              of "|": TkPipe
              of "(": TkLeftParen
              of ")": TkRightParen
              of "[": TkLeftBracket
              of "]": TkRightBracket
              else: TkSymbol
            if currentToken.kind == TkSymbol:
              currentToken.value = matchStr
          of "Token":
            currentToken.endPos = start + length
            tokens.add(currentToken)
            updateLineColumn(matchStr)
            position = start + length
          of "Whitespaces":
            echo "whitespace: \"", matchStr, "\""
            updateLineColumn(matchStr)
            position = start + length
          else:
            discard

  discard parse(input)
  if position < input.len:
    raise newException(LexerError, "Failed to parse input at position: " & $position & " line: " & $line & " column: " & $column)

  tokens

proc lex*(input: string): seq[Section] =
  result = lexSections(input)

  for section in result:
    if section.sectionType == Text:
      continue
    
    section.tokens = lexLiquid(section.content)
