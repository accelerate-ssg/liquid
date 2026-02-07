import strutils, base64, xmltree, sequtils, re

import ../shared


# Appends a string to another string
create_filter:
  proc append(value: VMValue, suffix: VMValue): VMValue =
    let input = to_string(value)
    let suffixStr = to_string(suffix)
    result = VMValue(kind: vmString, stringVal: input & suffixStr)

# Converts a string into a base64-decoded string
create_filter:
  proc base64_decode(value: VMValue): VMValue =
    if value.kind != vmString:
      return value
    result = VMValue(kind: vmString, stringVal: value.stringVal.decode())

# Converts a base64-encoded string into a string
create_filter:
  proc base64_encode(value: VMValue): VMValue =
    if value.kind != vmString:
      return value
    result = VMValue(kind: vmString, stringVal: value.stringVal.encode())

# Converts a string into a URL-safe base64-decoded string
create_filter:
  proc base64_url_safe_decode(value: VMValue): VMValue =
    if value.kind != vmString:
      return value
    result = VMValue(kind: vmString, stringVal: value.stringVal.decode())

# Converts a URL-safe base64-encoded string into a string
create_filter:
  proc base64_url_safe_encode(value: VMValue): VMValue =
    if value.kind != vmString:
      return value
    result = VMValue(kind: vmString, stringVal: value.stringVal.encode(safe = true))

# Capitalizes the first word in a string and downcases the remaining characters
create_filter:
  proc capitalize(value: VMValue): VMValue =
    if value.kind != vmString:
      return value
    var str = value.stringVal.toLower()
    if str.len > 0:
      str[0] = str[0].toUpperAscii()
    result = VMValue(kind: vmString, stringVal: str)

# Converts a string into a camelized string
create_filter:
  proc camelize(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmString:
      return value
    let parts = value.stringVal.split("_")
    let camelized = parts.mapIt(it.capitalizeAscii()).join("")
    result = VMValue(kind: vmString, stringVal: camelized)

# downcase - Converts a string to all lowercase characters
create_filter:
  proc downcase(value: VMValue): VMValue =
    if value.kind != vmString:
      return value
    result = VMValue(kind: vmString, stringVal: value.stringVal.toLower())

# escape - Escapes special characters in HTML
create_filter:
  proc escape(value: VMValue): VMValue =
    let input = to_string(value)
    if input.len == 0:
      return VMValue(kind: vmString, stringVal: "")
    # Custom HTML escape that handles single quotes (xmltree.escape doesn't)
    var escaped = newStringOfCap(input.len + 10)
    for c in input:
      case c
      of '&': escaped.add("&amp;")
      of '<': escaped.add("&lt;")
      of '>': escaped.add("&gt;")
      of '"': escaped.add("&quot;")
      of '\'': escaped.add("&#39;")
      else: escaped.add(c)
    result = VMValue(kind: vmString, stringVal: escaped)

# Converts a string into a URL-friendly format
create_filter:
  proc handleize(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmString:
      return value
    var str = value.stringVal.toLower()
    str = strutils.replace(str, " ", "-")
    str = re.replace(str, re"[^-\w]", "")
    result = VMValue(kind: vmString, stringVal: str)

# Strips all leading and trailing whitespace from a string
create_filter:
  proc strip(value: VMValue): VMValue =
    if value.kind != vmString:
      return value
    result = VMValue(kind: vmString, stringVal: value.stringVal.strip())

# Returns the first N characters of a string
create_filter:
  proc truncate(value: VMValue, args: varargs[VMValue]): VMValue =
    let input = to_string(value)

    if args.len > 2:
      raise newException(ValueError, "truncate filter takes at most 2 arguments")

    # Handle length argument
    let length = if args.len > 0:
      case args[0].kind
      of vmInt: args[0].intVal.int
      of vmFloat: args[0].floatVal.int
      of vmString:
        try: args[0].stringVal.parseInt()
        except: 50
      else: 50
    else:
      50

    # Handle ellipsis: undefined (vmNull) → empty string, missing → "..."
    let ellipsis = if args.len > 1:
      if args[1].kind == vmNull: ""
      else: to_string(args[1])
    else:
      "..."

    if input.len <= length:
      result = VMValue(kind: vmString, stringVal: input)
    else:
      let cutLen = max(0, length - ellipsis.len)
      result = VMValue(kind: vmString, stringVal: input[0..<cutLen] & ellipsis)

# Returns the first N words of a string, preserving whole words
create_filter:
  proc truncatewords(value: VMValue, args: varargs[VMValue]): VMValue =
    let input = to_string(value)

    if args.len > 2:
      raise newException(ValueError, "truncatewords filter takes at most 2 arguments")

    # Handle word count argument
    var wordCount = if args.len > 0:
      case args[0].kind
      of vmInt: args[0].intVal.int
      of vmFloat: args[0].floatVal.int
      of vmString:
        try: args[0].stringVal.parseInt()
        except: 15
      else: 15
    else:
      15

    # Minimum word count is 1 in Liquid
    if wordCount < 1:
      wordCount = 1

    # Handle ellipsis: undefined (vmNull) → empty string, missing → "..."
    # Non-string arg → convert to string
    let ellipsis = if args.len > 1:
      if args[1].kind == vmNull: ""
      else: to_string(args[1])
    else:
      "..."

    # Split on whitespace (handles multiple spaces, tabs, newlines)
    let words = input.splitWhitespace()
    if words.len <= wordCount:
      result = VMValue(kind: vmString, stringVal: words.join(" "))
    else:
      result = VMValue(kind: vmString, stringVal: words[0..<wordCount].join(" ") & ellipsis)

# upcase - Converts a string to all uppercase characters
create_filter:
  proc upcase(value: VMValue): VMValue =
    if value.kind != vmString:
      return value
    result = VMValue(kind: vmString, stringVal: value.stringVal.toUpper())

# Prepends a string to another string
create_filter:
  proc prepend(value: VMValue, prefix: VMValue): VMValue =
    let input = to_string(value)
    let prefixStr = to_string(prefix)
    result = VMValue(kind: vmString, stringVal: prefixStr & input)

# Removes a substring from a string
create_filter:
  proc remove(value: VMValue, substring: VMValue): VMValue =
    if value.kind != vmString:
      return value
    let substringStr = to_string(substring)
    result = VMValue(kind: vmString, stringVal: value.stringVal.replace(substringStr, ""))

# Removes the first occurrence of a substring from a string
create_filter:
  proc remove_first(value: VMValue, substring: VMValue): VMValue =
    if value.kind != vmString:
      return value
    let substringStr = to_string(substring)
    let idx = value.stringVal.find(substringStr)
    var resultStr = value.stringVal
    if idx >= 0:
      resultStr = value.stringVal[0..<idx] & value.stringVal[idx + substringStr.len..^1]
    result = VMValue(kind: vmString, stringVal: resultStr)

# Replaces all occurrences of a substring with another string
create_filter:
  proc replace(value: VMValue, args: varargs[VMValue]): VMValue =
    let input = to_string(value)

    if args.len < 1:
      raise newException(ValueError, "replace filter requires at least 1 argument (search string)")
    if args.len > 2:
      raise newException(ValueError, "replace filter takes at most 2 arguments")

    let searchStr = to_string(args[0])
    let replacementStr = if args.len >= 2: to_string(args[1]) else: ""
    result = VMValue(kind: vmString, stringVal: input.replace(searchStr, replacementStr))

# Replaces the first occurrence of a substring with another string
create_filter:
  proc replace_first(value: VMValue, search: VMValue, replacement: VMValue): VMValue =
    if value.kind != vmString:
      return value
    let searchStr = to_string(search)
    let replacementStr = to_string(replacement)
    let idx = value.stringVal.find(searchStr)
    var resultStr = value.stringVal
    if idx >= 0:
      resultStr = value.stringVal[0..<idx] & replacementStr & value.stringVal[idx + searchStr.len..^1]
    result = VMValue(kind: vmString, stringVal: resultStr)

# Strips HTML tags from a string
create_filter:
  proc strip_html(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmString:
      return value
    # Simple HTML tag removal
    let stripped = re.replace(value.stringVal, re"<[^>]*>", "")
    result = VMValue(kind: vmString, stringVal: stripped)

# Strips newlines from a string
create_filter:
  proc strip_newlines(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmString:
      return value
    let stripped = value.stringVal.multiReplace([("\n", ""), ("\r", "")])
    result = VMValue(kind: vmString, stringVal: stripped)

# Converts newlines to HTML breaks
create_filter:
  proc newline_to_br(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmString:
      return value
    let replaced = value.stringVal.replace("\n", "<br />")
    result = VMValue(kind: vmString, stringVal: replaced)

# Removes the last occurrence of a substring from a string
create_filter:
  proc remove_last(value: VMValue, substring: VMValue): VMValue =
    if value.kind != vmString:
      return value
    let substringStr = to_string(substring)
    let idx = value.stringVal.rfind(substringStr)
    var resultStr = value.stringVal
    if idx >= 0:
      resultStr = value.stringVal[0..<idx] & value.stringVal[idx + substringStr.len..^1]
    result = VMValue(kind: vmString, stringVal: resultStr)

# Replaces the last occurrence of a substring with another string  
create_filter:
  proc replace_last(value: VMValue, search: VMValue, replacement: VMValue): VMValue =
    if value.kind != vmString:
      return value
    let searchStr = to_string(search)
    let replacementStr = to_string(replacement)
    let idx = value.stringVal.rfind(searchStr)
    var resultStr = value.stringVal
    if idx >= 0:
      resultStr = value.stringVal[0..<idx] & replacementStr & value.stringVal[idx + searchStr.len..^1]
    result = VMValue(kind: vmString, stringVal: resultStr)

# Removes leading whitespace from a string
create_filter:
  proc lstrip(value: VMValue): VMValue =
    if value.kind != vmString:
      return value
    var i = 0
    while i < value.stringVal.len and value.stringVal[i] in {' ', '\t', '\n', '\r'}:
      inc i
    if i == 0:
      return value
    result = VMValue(kind: vmString, stringVal: value.stringVal[i..^1])

# Removes trailing whitespace from a string
create_filter:
  proc rstrip(value: VMValue): VMValue =
    if value.kind != vmString:
      return value
    var i = value.stringVal.len - 1
    while i >= 0 and value.stringVal[i] in {' ', '\t', '\n', '\r'}:
      dec i
    if i == value.stringVal.len - 1:
      return value
    result = VMValue(kind: vmString, stringVal: value.stringVal[0..i])

# Extracts a substring from a string, or a slice from an array
create_filter:
  proc slice(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind notin {vmString, vmArray}:
      return VMValue(kind: vmNull)
    if args.len < 1:
      raise newException(ValueError, "slice filter requires at least 1 argument (start index)")
    if args.len > 2:
      raise newException(ValueError, "slice filter takes at most 2 arguments")

    # Parse start index with strict type checking
    if args[0].kind == vmNull:
      raise newException(ValueError, "slice filter: first argument cannot be undefined")
    if args[0].kind == vmFloat:
      raise newException(ValueError, "slice filter: first argument must be an integer, not a float")
    var startIdx: int
    if args[0].kind == vmInt:
      startIdx = args[0].intVal.int
    elif args[0].kind == vmString:
      try:
        startIdx = args[0].stringVal.parseInt()
      except:
        raise newException(ValueError, "slice filter: first argument must be an integer")
    else:
      raise newException(ValueError, "slice filter: first argument must be an integer")

    var length = 1
    if args.len > 1:
      if args[1].kind == vmNull:
        length = 1
      elif args[1].kind == vmFloat:
        raise newException(ValueError, "slice filter: second argument must be an integer, not a float")
      elif args[1].kind == vmInt:
        length = args[1].intVal.int
      elif args[1].kind == vmString:
        try:
          length = args[1].stringVal.parseInt()
        except:
          raise newException(ValueError, "slice filter: second argument must be an integer")
      else:
        raise newException(ValueError, "slice filter: second argument must be an integer")

    if value.kind == vmString:
      let str = value.stringVal
      let actualStart = if startIdx < 0: max(0, str.len + startIdx) else: startIdx
      if length <= 0 or actualStart >= str.len:
        result = VMValue(kind: vmString, stringVal: "")
      else:
        let endIdx = min(actualStart + length, str.len)
        result = VMValue(kind: vmString, stringVal: str[actualStart..<endIdx])
    else:  # vmArray
      let arr = value.arrayVal
      let actualStart = if startIdx < 0: max(0, arr.len + startIdx) else: startIdx
      if length <= 0 or actualStart >= arr.len:
        result = VMValue(kind: vmArray, arrayVal: @[])
      else:
        let endIdx = min(actualStart + length, arr.len)
        result = VMValue(kind: vmArray, arrayVal: arr[actualStart..<endIdx])

# HTML escapes a string, but only if it hasn't been escaped already  
create_filter:
  proc escape_once(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmString:
      return value
    var str = value.stringVal
    # Only escape if not already escaped
    if "&amp;" notin str and "&lt;" notin str and "&gt;" notin str and "&quot;" notin str:
      str = xmltree.escape(str)
    result = VMValue(kind: vmString, stringVal: str)

# Splits a string into an array using a delimiter
create_filter:
  proc split(value: VMValue, args: varargs[VMValue]): VMValue =
    if args.len == 0:
      raise newException(ValueError, "split filter requires exactly 1 argument")
    if args.len > 1:
      raise newException(ValueError, "split filter takes at most 1 argument")

    let input = to_string(value)
    if input.len == 0:
      return VMValue(kind: vmArray, arrayVal: @[VMValue(kind: vmString, stringVal: "")])

    let delim = to_string(args[0])

    if delim.len == 0:
      # Empty delimiter: split into individual characters
      var chars: seq[VMValue] = @[]
      for c in input:
        chars.add(VMValue(kind: vmString, stringVal: $c))
      result = VMValue(kind: vmArray, arrayVal: chars)
    else:
      let parts = input.split(delim)
      let vmParts = parts.mapIt(VMValue(kind: vmString, stringVal: it))
      result = VMValue(kind: vmArray, arrayVal: vmParts)