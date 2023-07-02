import parlexgen
import std/[strutils, strformat,  options]

import liquid/types

makeLexer variable_lexer*[Token]:
  r"\{\{-": Token(kind: WHITESPACE_CONTROL)
  r"-\}\}": Token(kind: WHITESPACE_CONTROL)
  r"\{\%-": Token(kind: WHITESPACE_CONTROL)
  r"-\%\}": Token(kind: WHITESPACE_CONTROL)

  r"""\"\w*\"""": # " # Just to fix the syntax highlighting
    echo "Found string literal: ", match
    Token(kind: STRING_LITERAL, string_value: match[1 .. ^2])
  r"'\w*'":
    echo "Found string literal: ", match
    Token(kind: STRING_LITERAL, string_value: match[1 .. ^2])

  r"[a-zA-Z][a-zA-Z0-9_\-\.]*": Token(kind: IDENTIFIER, identifier_name: match)

  r"\d+\.\d+": Token(kind: FLOAT_LITERAL, float_value: parseFloat(match))
  r"\d+": Token(kind: INTEGER_LITERAL, integer_value: parseInt(match))

  r"\|": Token(kind: PIPE)
  r"\:": Token(kind: COLON)
  r",": Token(kind: COMMA)

  # Ignore the normal start and end tags, and whitespace
  # Since we go through the high level parser, we know the type of block anyway
  r"\{\{": continue
  r"\}\}": continue
  r"\s+": continue
