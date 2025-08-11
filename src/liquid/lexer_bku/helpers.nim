import sequtils, strutils

import ../types

proc initLexer*(input: string): Lexer =
  Lexer(input: input, position: 0, line: 1, column: 0)

# Sliding window optimization - use string slicing for efficient pattern matching
template getWindow*(l: Lexer, size: int): string =
  if l.position + size <= l.input.len:
    l.input[l.position..<l.position + size]
  else:
    l.input[l.position..^1]

template matchesAt*(l: Lexer, pattern: string): bool =
  l.position + pattern.len <= l.input.len and 
  l.input[l.position..<l.position + pattern.len] == pattern


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

# Optimized bulk advance for text sections
proc advanceBulk*(l: var Lexer, count: int): string =
  if l.isAtEnd or count <= 0: return ""
  let endPos = min(l.position + count, l.input.len)
  result = l.input[l.position..<endPos]
  # Update position tracking more efficiently
  for i in l.position..<endPos:
    if l.input[i] == '\n':
      l.line += 1
      l.column = 1
    else:
      l.column += 1
  l.position = endPos

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

# Optimized bulk peek function
proc peekString*(l: Lexer, length: int): string =
  if l.isAtEnd or length <= 0: return ""
  let endPos = min(l.position + length, l.input.len)
  result = l.input[l.position..<endPos]

# Fast pattern matching without advancing
proc matchPattern*(l: Lexer, pattern: string): bool =
  if l.position + pattern.len > l.input.len: return false
  for i in 0..<pattern.len:
    if l.input[l.position + i] != pattern[i]:
      return false
  return true

# Find next occurrence of pattern efficiently
proc findPattern*(l: Lexer, pattern: string): int =
  if l.isAtEnd: return -1
  let searchStart = l.position
  let searchEnd = l.input.len - pattern.len
  if searchStart > searchEnd: return -1
  
  for i in searchStart..searchEnd:
    var matches = true
    for j in 0..<pattern.len:
      if l.input[i + j] != pattern[j]:
        matches = false
        break
    if matches:
      return i
  return -1

# Fast scan to a pattern and return the content before it
# Returns tuple of (content, found)
proc scanToPattern*(l: var Lexer, pattern: string): tuple[content: string, found: bool] =
  let startPos = l.position
  let patternPos = l.findPattern(pattern)
  
  if patternPos >= 0:
    # Found the pattern, advance to it
    result.content = l.input[startPos..<patternPos]
    l.position = patternPos
    # Update line/column tracking
    for i in startPos..<patternPos:
      if l.input[i] == '\n':
        l.line += 1
        l.column = 1
      else:
        l.column += 1
    result.found = true
  else:
    # Pattern not found, consume rest
    result.content = l.input[startPos..^1]
    l.position = l.input.len
    # Update line/column tracking
    for i in startPos..<l.input.len:
      if l.input[i] == '\n':
        l.line += 1
        l.column = 1
      else:
        l.column += 1
    result.found = false

# Fast scan to any of multiple patterns and return the content before it
# Returns tuple of (content, patternIndex, found)
proc scanToPatterns*(l: var Lexer, patterns: openarray[string]): tuple[content: string, patternIndex: int, found: bool] =
  let startPos = l.position
  var minPos = l.input.len
  var minIndex = -1
  
  # Find the closest pattern
  for i, pattern in patterns:
    let pos = l.findPattern(pattern)
    if pos >= 0 and pos < minPos:
      minPos = pos
      minIndex = i
  
  if minIndex >= 0:
    # Found a pattern, advance to it
    result.content = l.input[startPos..<minPos]
    l.position = minPos
    # Update line/column tracking
    for i in startPos..<minPos:
      if l.input[i] == '\n':
        l.line += 1
        l.column = 1
      else:
        l.column += 1
    result.patternIndex = minIndex
    result.found = true
  else:
    # No pattern found, consume rest
    result.content = l.input[startPos..^1]
    l.position = l.input.len
    # Update line/column tracking
    for i in startPos..<l.input.len:
      if l.input[i] == '\n':
        l.line += 1
        l.column = 1
      else:
        l.column += 1
    result.patternIndex = -1
    result.found = false

proc `$`*(token: Token): string =
  "<" & $token.kind & ": " & token.value & ">"

proc `$`*(tokens: seq[Token]): string =
  tokens.mapIt($it).join("\n")
