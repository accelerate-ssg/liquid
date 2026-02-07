when defined(posix) or defined(windows):
  when defined(windows):
    proc memchr(s: pointer, c: cint, n: csize_t): pointer {.importc, header: "<string.h>".}
  else:
    proc memchr(s: pointer, c: cint, n: csize_t): pointer {.importc, header: "<string.h>".}

proc scan_end_tag*(input: string, pos: var int, endTag: static string, 
                        returnRawEnd: static bool = false): int {. inline .} =
  ## Ultra-fast scanning for {% endXXX %} tags using memchr
  ## 
  ## Parameters:
  ## - input: The string to scan
  ## - pos: Current position (updated to position after the end tag)
  ## - endTag: The end tag to look for (e.g., "endcomment", "endraw", "endcapture")
  ## - returnRawEnd: If true, returns position before {% (for raw blocks)
  ##                 If false, returns -1 (for comment blocks that don't need content)
  ## 
  ## Returns:
  ## - If returnRawEnd is true: Position where content ends (before {%)
  ## - If returnRawEnd is false: -1 (content is discarded)
  ## 
  ## Examples:
  ## - For comment: scan_end_tag(input, pos, "endcomment", false)
  ## - For raw: let rawEnd = scan_end_tag(input, pos, "endraw", true)
  ## - For capture: let captureEnd = scan_end_tag(input, pos, "endcapture", true)
  
  when returnRawEnd:
    result = pos  # Initialize to current position for raw-style blocks
  else:
    result = -1   # Comments don't need content position
  
  const endTagLen = endTag.len
  const minCharsNeeded = 5 + endTagLen  # "{% " + endTag + " %}" minimum
  
  when defined(posix) or defined(windows):
    let inputLen = input.len
    
    while pos < inputLen - minCharsNeeded:
      # Find next '{' character using memchr
      let searchStart = unsafeAddr input[pos]
      let searchLen = inputLen - pos
      let found = memchr(searchStart, '{'.ord.cint, searchLen.csize_t)
      
      if found.isNil:
        # No more '{' characters
        when returnRawEnd:
          result = inputLen
        pos = inputLen
        return
      
      # Calculate position of found '{'
      let foundPos = cast[int](found) - cast[int](unsafeAddr input[0])
      
      # Check if it's "{% endXXX %}"
      if foundPos < inputLen - minCharsNeeded and input[foundPos + 1] == '%':
        var checkPos = foundPos + 2
        
        # Skip optional '-'
        if checkPos < inputLen and input[checkPos] == '-':
          inc checkPos
        
        # Skip whitespace
        while checkPos < inputLen and input[checkPos] in {' ', '\t', '\r', '\n'}:
          inc checkPos
        
        # Check for the end tag
        if checkPos + endTagLen <= inputLen and 
           input.matchesAt(checkPos, endTag):
          # Found it!
          when returnRawEnd:
            result = foundPos  # Return position before the {%
          
          pos = checkPos + endTagLen
          
          # Skip whitespace after end tag
          while pos < inputLen and input[pos] in {' ', '\t', '\r', '\n'}:
            inc pos
          
          # Skip the closing %} or -%}
          if pos < inputLen - 1:
            if input.matchesAt(pos, "-%}"):
              pos += 3
            elif input.matchesAt(pos, "%}"):
              pos += 2
          return
      
      # Not our end tag, continue from next position
      pos = foundPos + 1
    
    # If we get here, we didn't find the end tag
    when returnRawEnd:
      result = inputLen
    pos = inputLen
    
  else:
    # Fallback for non-POSIX systems
    while pos < inputLen - 1:
      if input[pos] == '{' and input[pos + 1] == '%':
        when returnRawEnd:
          let foundPos = pos
        
        var checkPos = pos + 2
        
        if checkPos < inputLen and input[checkPos] == '-':
          inc checkPos
        
        while checkPos < inputLen and input[checkPos] in {' ', '\t', '\r', '\n'}:
          inc checkPos
        
        if input.matchesAt(checkPos, endTag):
          when returnRawEnd:
            result = foundPos
          
          pos = checkPos + endTagLen
          
          while pos < inputLen and input[pos] in {' ', '\t', '\r', '\n'}:
            inc pos
          
          if pos < inputLen - 1:
            if input.matchesAt(pos, "-%}"):
              pos += 3
            elif input.matchesAt(pos, "%}"):
              pos += 2
          return
      inc pos
    
    when returnRawEnd:
      result = inputLen
    pos = inputLen
