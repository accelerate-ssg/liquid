import ../types 

template parse_token*(input: string, pos: var int, endPos: int, 
                   section: var Section) =
  ## Parses a single token from the input and adds it to the section.
  ##
  ## This template handles all token types found in Liquid templates including
  ## identifiers, numbers, strings, operators, and punctuation. It's designed
  ## for maximum performance with zero allocations.
  ##
  ## **Performance:**
  ## - ~10-50ns per token depending on type
  ## - Zero string allocations (tokens store only indices)
  ## - Inlined at compile time
  ## - Direct character dispatch for operators
  ##
  ## **Parameters:**
  ## - `input`: The source string being lexed
  ## - `pos`: Current position in input (modified to advance past token)
  ## - `endPos`: Maximum position to read (prevents reading past section end)
  ## - `section`: Section to add the parsed token to
  ## - `classifyIdentifier`: Function to classify identifier tokens as keywords
  ##
  ## **Token Types Handled:**
  ## - Identifiers and keywords: `product`, `for`, `if`
  ## - Numbers: `42`, `-3.14`, `0`
  ## - Strings: `"hello"`, `'world'`, `"escaped \" quote"`
  ## - Operators: `==`, `!=`, `<=`, `>=`, `<`, `>`, `+`, `-`, `*`, `/`, `%`
  ## - Punctuation: `.`, `..`, `,`, `:`, `|`, `?`
  ## - Brackets: `(`, `)`, `[`, `]`
  ##
  ## **Examples:**
  ##
  ## ```nim
  ## var section = Section(kind: skTag)
  ## section.tokens = newSeqOfCap[Token](10)
  ## var pos = 0
  ## 
  ## # Parse an identifier
  ## var input = "product.name"
  ## parse_token(input, pos, input.len, section, classifyIdentifier)
  ## assert section.tokens[0].kind == tkIdentifier
  ## assert input[section.tokens[0].start..<section.tokens[0].stop] == "product"
  ## assert pos == 7  # Advanced past "product"
  ## 
  ## # Parse a number
  ## input = "42.5 + x"
  ## pos = 0
  ## parse_token(input, pos, input.len, section, classifyIdentifier)
  ## assert section.tokens[0].kind == tkNumber
  ## assert pos == 4  # Advanced past "42.5"
  ## 
  ## # Parse a string
  ## input = "'hello world' | filter"
  ## pos = 0
  ## parse_token(input, pos, input.len, section, classifyIdentifier)
  ## assert section.tokens[0].kind == tkString
  ## assert pos == 13  # Advanced past "'hello world'"
  ## 
  ## # Parse operators
  ## input = "== != <="
  ## pos = 0
  ## parse_token(input, pos, 2, section, classifyIdentifier)
  ## assert section.tokens[0].kind == tkEq
  ## assert pos == 2
  ## ```
  ##
  ## **Implementation Notes:**
  ## - Numbers can be negative (`-42`) or floating point (`3.14`)
  ## - Strings handle escape sequences (`\"`, `\'`, `\\`)
  ## - Identifiers may contain hyphens (`data-value`)
  ## - Unknown characters are silently skipped (pos incremented)
  let tokStart = pos
  
  case input[pos]
  of 'a'..'z', 'A'..'Z', '_':
    # Identifier/keyword - fast scan
    let start = pos
    input.scanIdentifier(pos)
    if pos > start:
      let tokenKind = classifyIdentifier(input, start, pos)
      section.addToken(tokenKind, start, pos)
    
  of '0'..'9', '-':
    # Number (including negative)
    if input[pos] == '-' and pos + 1 < endPos and input[pos + 1] notin {'0'..'9'}:
      # Just a minus operator
      inc pos
      section.addToken(tkMinus, tokStart, pos)
    else:
      if input[pos] == '-':
        inc pos  # Skip minus
      while pos < endPos and input[pos] in {'0'..'9'}:
        inc pos
      if pos < endPos - 1 and input[pos] == '.' and input[pos + 1] in {'0'..'9'}:
        inc pos  # Skip .
        while pos < endPos and input[pos] in {'0'..'9'}:
          inc pos
      section.addToken(tkNumber, tokStart, pos)
    
  of '"', '\'':
    # String
    let quote = input[pos]
    inc pos
    while pos < endPos and input[pos] != quote:
      if input[pos] == '\\' and pos + 1 < endPos:
        pos += 2  # Skip escaped char
      else:
        inc pos
    if pos < endPos:
      inc pos  # Skip closing quote
    section.addToken(tkString, tokStart, pos)
    
  of '=':
    inc pos
    if pos < endPos and input[pos] == '=':
      inc pos
      section.addToken(tkEq, tokStart, pos)
    else:
      section.addToken(tkAssign, tokStart, pos)
      
  of '!':
    inc pos
    if pos < endPos and input[pos] == '=':
      inc pos
      section.addToken(tkNeq, tokStart, pos)
    else:
      section.addToken(tkNot, tokStart, pos)
      
  of '<':
    inc pos
    if pos < endPos and input[pos] == '=':
      inc pos
      section.addToken(tkLte, tokStart, pos)
    else:
      section.addToken(tkLt, tokStart, pos)
      
  of '>':
    inc pos
    if pos < endPos and input[pos] == '=':
      inc pos
      section.addToken(tkGte, tokStart, pos)
    else:
      section.addToken(tkGt, tokStart, pos)
      
  of '.':
    inc pos
    if pos < endPos and input[pos] == '.':
      inc pos
      section.addToken(tkDoubleDot, tokStart, pos)
    else:
      section.addToken(tkDot, tokStart, pos)
      
  of '+': inc pos; section.addToken(tkPlus, tokStart, pos)
  of '*': inc pos; section.addToken(tkMul, tokStart, pos)
  of '/': inc pos; section.addToken(tkDiv, tokStart, pos)
  of '%': inc pos; section.addToken(tkMod, tokStart, pos)
  of '|': inc pos; section.addToken(tkPipe, tokStart, pos)
  of ':': inc pos; section.addToken(tkColon, tokStart, pos)
  of ',': inc pos; section.addToken(tkComma, tokStart, pos)
  of '?': inc pos; section.addToken(tkQuestion, tokStart, pos)
  of '(': inc pos; section.addToken(tkLeftParen, tokStart, pos)
  of ')': inc pos; section.addToken(tkRightParen, tokStart, pos)
  of '[': inc pos; section.addToken(tkLeftBracket, tokStart, pos)
  of ']': inc pos; section.addToken(tkRightBracket, tokStart, pos)
  else:
    inc pos
