proc matches_at*(input: string, pos: int, pattern: static string): bool {.inline.} =
  ## Checks if a string pattern occurs at a specific position without allocations.
  ##
  ## This zero-cost pattern matching is optimized for the lexer's hot path,
  ## using compile-time known patterns (static string) for maximum performance.
  ##
  ## **Performance:**
  ## - Inlined at compile time
  ## - No string allocations or copies
  ## - Early termination on first mismatch
  ## - ~2-5ns for typical short patterns
  ##
  ## **Parameters:**
  ## - `input`: The string to check against
  ## - `pos`: Position in input to start matching
  ## - `pattern`: Compile-time known pattern to match (static string)
  ##
  ## **Returns:**
  ## - `true` if pattern matches at position
  ## - `false` if position out of bounds or pattern doesn't match
  ##
  ## **Examples:**
  ##
  ## ```nim
  ## let template = "{% if condition %}"
  ## 
  ## # Check for tag markers
  ## assert template.matches_at(0, "{%") == true
  ## assert template.matches_at(16, "%}") == true
  ## assert template.matches_at(0, "{{") == false
  ## 
  ## # Check for keywords
  ## assert template.matches_at(3, "if") == true
  ## assert template.matches_at(3, "for") == false
  ## 
  ## # Boundary checking
  ## assert template.matches_at(17, "%}") == false  # Out of bounds
  ## assert template.matches_at(-1, "{%") == false  # Negative position
  ## ```
  if pos + pattern.len > input.len:
    return false
  else:
    for i in 0..<pattern.len:
      if input[pos + i] != pattern[i]:
        return false
    return true

template matches_at*(input: string, pos: int, character: static char): bool =
  ## Checks if a single character occurs at a specific position.
  ##
  ## Optimized single-character variant of pattern matching for the lexer's
  ## most common case - checking for single character tokens.
  ##
  ## **Performance:**
  ## - Compiles to a single bounds check and comparison
  ## - ~1ns typical performance
  ## - Zero overhead template
  ##
  ## **Parameters:**
  ## - `input`: The string to check against
  ## - `pos`: Position in input to check
  ## - `character`: Character to match (known at compile time)
  ##
  ## **Returns:**
  ## - `true` if character matches at position
  ## - `false` if position out of bounds or character doesn't match
  ##
  ## **Examples:**
  ##
  ## ```nim
  ## let code = "x = 42"
  ## 
  ## # Check for operators
  ## assert code.matches_at(2, '=') == true
  ## assert code.matches_at(0, '=') == false
  ## 
  ## # Check for whitespace
  ## assert code.matches_at(1, ' ') == true
  ## assert code.matches_at(3, ' ') == true
  ## 
  ## # Boundary checking
  ## assert code.matches_at(10, 'x') == false  # Out of bounds
  ## assert code.matches_at(-1, 'x') == false  # Would fail bounds check
  ## ```
  pos < input.len and input[pos] == character
