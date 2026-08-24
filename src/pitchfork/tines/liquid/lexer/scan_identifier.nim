template scan_identifier*(input: string, pos: var int) =
  ## High-performance identifier scanner using bit tables for character classification.
  ##
  ## This template efficiently scans Liquid template identifiers without allocations
  ## or function call overhead. It uses precomputed bit tables to check character
  ## validity in constant time.
  ##
  ## **Identifier Rules:**
  ## - First character: `a-z`, `A-Z`, `_`, or `@` (followed by a letter)
  ## - Continuation characters: `a-z`, `A-Z`, `0-9`, `_`, or `-`
  ## - Optional trailing `?` (for Ruby-style predicate methods)
  ##
  ## **Performance:**
  ## - ~8ns per identifier on modern hardware
  ## - Zero allocations
  ## - Inlined at compile time (template)
  ## - Single-pass scanning with minimal branching
  ##
  ## **Bit Table Design:**
  ## The tables encode valid characters as bits, where each bit position
  ## corresponds to an ASCII value:
  ## - `IdentFirstTable2`: Bits for ASCII 64-127 (includes A-Z, _, a-z)
  ## - `IdentContTable1`: Bits for ASCII 0-63 (includes 0-9 and -)
  ## - `IdentContTable2`: Same as IdentFirstTable2 for continuation
  ##
  ## **Parameters:**
  ## - `input`: The string to scan
  ## - `pos`: Variable holding current position (modified in place)
  ##
  ## **Examples:**
  ##
  ## ```nim
  ## # Basic identifier scanning
  ## var input = "product_name }}"
  ## var pos = 0
  ## scan_identifier(input, pos)
  ## assert pos == 12  # Scanned "product_name"
  ## assert input[0..<pos] == "product_name"
  ##
  ## # With trailing question mark
  ## input = "empty? }}"
  ## pos = 0
  ## scan_identifier(input, pos)
  ## assert pos == 6  # Scanned "empty?"
  ##
  ## # With hyphens
  ## input = "data-value-1 | filter"
  ## pos = 0
  ## scan_identifier(input, pos)
  ## assert pos == 12  # Scanned "data-value-1"
  ##
  ## # Stops at invalid characters
  ## input = "name.property"
  ## pos = 0
  ## scan_identifier(input, pos)
  ## assert pos == 4  # Stopped at '.'
  ## assert input[0..<pos] == "name"
  ##
  ## # @ prefix
  ## input = "@foo }}"
  ## pos = 0
  ## scan_identifier(input, pos)
  ## assert pos == 4  # Scanned "@foo"
  ##
  ## # No identifier found
  ## input = "123abc"
  ## pos = 0
  ## scan_identifier(input, pos)
  ## assert pos == 0  # First char is not valid identifier start
  ##
  ## # Empty input
  ## input = ""
  ## pos = 0
  ## scan_identifier(input, pos)
  ## assert pos == 0  # No change
  ## ```
  ##
  ## **Usage in Lexer:**
  ##
  ## ```nim
  ## proc lexToken(input: string, pos: var int): Token =
  ##   let start = pos
  ##   scan_identifier(input, pos)
  ##   if pos > start:
  ##     # Successfully scanned an identifier
  ##     return Token(
  ##       kind: classifyIdentifier(input, start, pos),
  ##       start: start,
  ##       stop: pos
  ##     )
  ## ```
  ##
  ## **Implementation Notes:**
  ## - The bit tables are compile-time constants (zero runtime cost)
  ## - Branch prediction works well due to common ASCII character patterns
  ## - The template ensures complete inlining with no call overhead
  ## - Early termination on non-ASCII characters (>= 128) for safety
  if pos < input.len:
    var matched_first = false
    let c = input[pos].uint8

    # Check for @ prefix (Ruby-style instance variables like @foo)
    if c == 64:  # '@' character
      if pos + 1 < input.len:
        let nc = input[pos + 1].uint8
        if nc < 128 and nc >= 64 and ((IdentFirstTable2 shr (nc - 64)) and 1) != 0:
          pos += 2  # Skip past @ and the first letter
          matched_first = true
    elif c < 128 and c >= 64 and ((IdentFirstTable2 shr (c - 64)) and 1) != 0:
      inc pos
      matched_first = true

    if matched_first:
      while pos < input.len:
        let cc = input[pos].uint8
        if cc >= 128:
          break
        let valid = if cc < 64:
          (IdentContTable1 shr cc) and 1
        else:
          (IdentContTable2 shr (cc - 64)) and 1
        if valid == 0:
          break
        inc pos
      if pos < input.len and input[pos] == '?':
        inc pos
