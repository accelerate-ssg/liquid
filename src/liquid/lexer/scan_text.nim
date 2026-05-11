when defined(posix) or defined(windows):
  when defined(windows):
    # Windows has memchr in string.h
    proc memchr(s: pointer, c: cint, n: csize_t): pointer {.importc, header: "<string.h>".}
  else:
    # POSIX systems
    proc memchr(s: pointer, c: cint, n: csize_t): pointer {.importc, header: "<string.h>".}

template scan_text*(input: string, pos: var int) =
  ## Ultra-fast text scanning using system memchr
  ## Falls back to optimized pure Nim on non-POSIX systems
  when defined(posix) or defined(windows):
    let inputLen = input.len
    if pos >= inputLen:
      return
    
    let maxPos = inputLen - 1
    while pos < maxPos:
      # Search for '{' using memchr - this is the key optimization
      let searchStart = unsafeAddr input[pos]
      let searchLen = inputLen - pos
      let found = memchr(searchStart, '{'.ord.cint, searchLen.csize_t)
      
      if found.isNil:
        # No more '{' characters in the rest of the string
        pos = inputLen
        break
      
      # Calculate position of found '{'
      pos = cast[int](found) - cast[int](unsafeAddr input[0])
      
      # Check if it's followed by '{' or '%' to indicate a tag
      if pos < maxPos:
        let next = input[pos + 1]
        if next == '{' or next == '%':
          break  # Found a tag start!
      
      # Not a tag, continue searching from next position
      inc pos
    
    # Handle edge case where we're at the last position
    if pos == maxPos and input[pos] != '{':
      inc pos
  else:
    # Fallback for systems without memchr
    # This is still faster than the original due to reduced bounds checking
    let maxPos = input.len - 1
    while pos < maxPos:
      if input[pos] == '{':
        let next = input[pos + 1]
        if next == '{' or next == '%':
          break
      inc pos
    
    if pos == maxPos and input[pos] != '{':
      inc pos
