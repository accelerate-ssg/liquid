import strutils, base64, xmltree, json, sequtils, re

import ../shared

# Appends a string to another string
#append : string suffix:string
create_filter:
  proc append(input: string, suffix: string): string =
    result = input & suffix

# Converts a string into a base64-encoded string
#base64_decode : string
create_filter:
  proc base64_decode(input: string): string =
    result = input.decode()

# Converts a base64-encoded string into a string
#base64_encode : string
create_filter:
  proc base64_encode(input: string): string =
    result = input.encode()

# Converts a string into a URL-safe base64-encoded string
#base64_url_safe_decode : string
create_filter:
  proc base64_url_safe_decode(input: string): string =
    result = input.decode()

# Converts a URL-safe base64-encoded string into a string
#base64_url_safe_encode : string
create_filter:
  proc base64_url_safe_encode(input: string): string =
    result = input.encode(safe = true)

##
# Capitalizes the first word in a string and downcases the remaining characters.
# capitalize : string
# returns string
##
create_filter:
  proc capitalize(input: string): string =
    result = input.toLower()
    result = result[0..1].toUpper() & result[1..^1]

# Converts a string into a camelized string
#camelize : string
create_filter:
  proc camelize(input: string): string =
    result = input.split("_").map(proc(x: string): string = x.toUpper).join("")


# downcase
# string | downcase
# returns string
# Converts a string to all lowercase characters.
create_filter:
  proc downcase(input: string): string =
    result = input.toLower()

# escape
# string | escape
# returns string
# Escapes special characters in HTML, such as <>, ', and &, and converts characters into escape sequences. The filter doesn't effect characters within the string that don’t have a corresponding escape sequence.".
create_filter:
  proc escape(input: string): string =
    result = xmltree.escape(input)


# Converts a string into a URL-friendly format
create_filter:
  proc handleize(input: string): string =
    result = input.toLower()
    result = strutils.replace(result, " ", "-")
    result = re.replace(result, re"([^-\w])")



# Removes HTML tags from a string
#strip_html : string

# Strips all leading and trailing whitespace from a string
create_filter:
  proc strip(input: string): string =
    result = input.strip()

# Returns the first characters of a string
#truncate : length:number [ellipsis:string]
create_filter:
  proc truncate(input: string, length: int, ellipsis: string = "..."): string =
    result = input

    if input.len > length:
      result = input[0..length-1] & ellipsis

# Returns the first characters of a string, preserving whole words
#truncatewords : length:number [ellipsis:string]
create_filter:
  proc truncatewords(input: string, length: int, ellipsis: string = "..."): string =
    result = input

    if input.len > length:
      result = input[0..length-1]
      result = result.rsplit(" ", 1)[0] & ellipsis

# Replaces newline characters with HTML line breaks
#newline_to_br : string
create_filter:
  proc newline_to_br(input: string): string =
    result = input.replace("\n", "<br>")

# Converts a string to uppercase
#upcase : string
create_filter:
  proc upcase(input: string): string =
    result = input.toUpper()

# Replaces occurrences of one string with another
#replace : string old:string new:string
create_filter:
  proc replace(input: string, old: string, replacement: string): string =
    result = strutils.replace(input, old, replacement)

# Replaces the first occurrence of one string with another
#replace_first : string old:string new:string
create_filter:
  proc replace_first(input: string, old: string, replacement: string): string =
    result = strutils.split(input, old, 1).join(replacement)

# Splits a string into an array using a delimiter
#split : string delimiter:string
create_filter:
  proc split(input: string, delimiter: string): seq[string] =
    result = input.split(delimiter)

# Removes all whitespace from a string
#strip_newlines : string
create_filter:
  proc strip_newlines(input: string): string =
    result = input.replace("\n", "")


# Removes specified characters from the beginning of a string
create_filter:
  proc lstrip(input: string, chars: string = " \t\n\r"): string =
    var i = 0
    while i < input.len and input[i] in chars:
      inc i
    result = input[i..^1]

# Removes specified characters from the end of a string
create_filter:
  proc rstrip(input: string, chars: string = " \t\n\r"): string =
    var i = input.len - 1
    while i >= 0 and input[i] in chars:
      dec i
    result = input[0..i]

# Reverses the characters in a string
create_filter:
  proc reverse(input: string): string =
    result = ""
    for i in countdown(input.len - 1, 0):
      result.add(input[i])

# Returns the size/length of a string
create_filter:
  proc size(input: string): int =
    result = input.len

# Prepends a string to another string
create_filter:
  proc prepend(input: string, prefix: string): string =
    result = prefix & input

# Escapes a string for use in a URL
create_filter:
  proc url_encode(input: string): string =
    result = ""
    for c in input:
      case c
      of 'a'..'z', 'A'..'Z', '0'..'9', '-', '_', '.', '~':
        result.add(c)
      of ' ':
        result.add('+')
      else:
        result.add('%')
        result.add(toHex(ord(c), 2))

# Unescapes a URL-encoded string
create_filter:
  proc url_decode(input: string): string =
    result = ""
    var i = 0
    while i < input.len:
      if input[i] == '+':
        result.add(' ')
        inc i
      elif input[i] == '%' and i + 2 < input.len:
        try:
          let hex = input[i+1..i+2]
          result.add(chr(parseHexInt(hex)))
          i += 3
        except:
          result.add(input[i])
          inc i
      else:
        result.add(input[i])
        inc i

# escape_once was implemented above as a commented TODO, let's fix it
create_filter:
  proc escape_once(input: string): string =
    # Check if string contains HTML entities
    if "&amp;" in input or "&lt;" in input or "&gt;" in input or "&quot;" in input or "&#39;" in input:
      # Already escaped, return as-is
      result = input
    else:
      result = xmltree.escape(input)


# Returns a slice of a string
create_filter:
  proc slice(input: string, start: int, length: int = -1): string =
    let actualStart = if start < 0: input.len + start else: start
    if actualStart < 0 or actualStart >= input.len:
      return ""
    
    if length < 0:
      result = input[actualStart..^1]
    else:
      let endIdx = min(actualStart + length - 1, input.len - 1)
      result = input[actualStart..endIdx]


# Removes all HTML tags from a string
create_filter:
  proc strip_html(input: string): string =
    result = re.replace(input, re"<[^>]*>")

# Removes all occurrences of a substring from a string
create_filter:
  proc remove(input: string, substring: string): string =
    result = input.replace(substring, "")

# Removes the first occurrence of a substring from a string
create_filter:
  proc remove_first(input: string, substring: string): string =
    let idx = input.find(substring)
    if idx >= 0:
      result = input[0..<idx] & input[idx + substring.len..^1]
    else:
      result = input

# Removes the last occurrence of a substring from a string
create_filter:
  proc remove_last(input: string, substring: string): string =
    let idx = input.rfind(substring)
    if idx >= 0:
      result = input[0..<idx] & input[idx + substring.len..^1]
    else:
      result = input

# replace_last - Replaces the last occurrence of a substring
create_filter:
  proc replace_last(input: string, old: string, replacement: string): string =
    let idx = input.rfind(old)
    if idx >= 0:
      result = input[0..<idx] & replacement & input[idx + old.len..^1]
    else:
      result = input

