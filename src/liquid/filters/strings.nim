import strutils, base64, xmltree, sequtils, re

import ../shared

# Helper to get string value or convert to string
proc getStringVal(v: VMValue): string =
  case v.kind
  of vmString: v.stringVal
  of vmInt: $v.intVal
  of vmFloat: $v.floatVal
  of vmBool: $v.boolVal
  of vmNull: ""
  else: ""  # Arrays and objects would need special handling

# Appends a string to another string
create_filter:
  proc append(value: VMValue, suffix: VMValue): VMValue =
    let input = getStringVal(value)
    let suffixStr = getStringVal(suffix)
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
    if value.kind != vmString:
      return value
    result = VMValue(kind: vmString, stringVal: xmltree.escape(value.stringVal))

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
    if value.kind != vmString:
      return value
    
    if args.len > 2:
      raise newException(ValueError, "truncate filter takes at most 2 arguments")
    
    # Handle length argument
    let length = if args.len > 0:
      if args[0].kind == vmNull:
        raise newException(ValueError, "truncate filter length argument is undefined")
      elif args[0].kind == vmInt:
        args[0].intVal.int
      else:
        50  # Default for invalid types
    else:
      50  # Default when no arguments
    let ellipsis = if args.len > 1 and args[1].kind == vmString: args[1].stringVal else: "..."
    
    var str = value.stringVal
    if str.len > length:
      str = str[0..<length] & ellipsis
    
    result = VMValue(kind: vmString, stringVal: str)

# Returns the first N words of a string, preserving whole words
create_filter:
  proc truncatewords(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmString:
      return value
    
    if args.len > 2:
      raise newException(ValueError, "truncatewords filter takes at most 2 arguments")
    
    # Handle word count argument
    let wordCount = if args.len > 0:
      if args[0].kind == vmNull:
        raise newException(ValueError, "truncatewords filter word count argument is undefined")
      elif args[0].kind == vmInt:
        args[0].intVal.int
      else:
        15  # Default for invalid types
    else:
      15  # Default when no arguments
    let ellipsis = if args.len > 1 and args[1].kind == vmString: args[1].stringVal else: "..."
    
    let words = value.stringVal.split()
    var resultStr: string
    if words.len <= wordCount:
      resultStr = value.stringVal
    else:
      resultStr = words[0..<wordCount].join(" ") & ellipsis
    
    result = VMValue(kind: vmString, stringVal: resultStr)

# upcase - Converts a string to all uppercase characters
create_filter:
  proc upcase(value: VMValue): VMValue =
    if value.kind != vmString:
      return value
    result = VMValue(kind: vmString, stringVal: value.stringVal.toUpper())

# Prepends a string to another string
create_filter:
  proc prepend(value: VMValue, prefix: VMValue): VMValue =
    let input = getStringVal(value)
    let prefixStr = getStringVal(prefix)
    result = VMValue(kind: vmString, stringVal: prefixStr & input)

# Removes a substring from a string
create_filter:
  proc remove(value: VMValue, substring: VMValue): VMValue =
    if value.kind != vmString:
      return value
    let substringStr = getStringVal(substring)
    result = VMValue(kind: vmString, stringVal: value.stringVal.replace(substringStr, ""))

# Removes the first occurrence of a substring from a string
create_filter:
  proc remove_first(value: VMValue, substring: VMValue): VMValue =
    if value.kind != vmString:
      return value
    let substringStr = getStringVal(substring)
    let idx = value.stringVal.find(substringStr)
    var resultStr = value.stringVal
    if idx >= 0:
      resultStr = value.stringVal[0..<idx] & value.stringVal[idx + substringStr.len..^1]
    result = VMValue(kind: vmString, stringVal: resultStr)

# Replaces all occurrences of a substring with another string
create_filter:
  proc replace(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmString:
      return value
    
    if args.len < 1:
      raise newException(ValueError, "replace filter requires at least 1 argument (search string)")
    if args.len > 2:
      raise newException(ValueError, "replace filter takes at most 2 arguments")
    
    let searchStr = getStringVal(args[0])
    let replacementStr = if args.len >= 2: getStringVal(args[1]) else: ""
    result = VMValue(kind: vmString, stringVal: value.stringVal.replace(searchStr, replacementStr))

# Replaces the first occurrence of a substring with another string
create_filter:
  proc replace_first(value: VMValue, search: VMValue, replacement: VMValue): VMValue =
    if value.kind != vmString:
      return value
    let searchStr = getStringVal(search)
    let replacementStr = getStringVal(replacement)
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
    let substringStr = getStringVal(substring)
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
    let searchStr = getStringVal(search)
    let replacementStr = getStringVal(replacement)
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
    var s = value.stringVal
    while s.len > 0 and s[0] in {' ', '\t', '\n', '\r'}:
      s = s[1..^1]
    result = VMValue(kind: vmString, stringVal: s)

# Removes trailing whitespace from a string  
create_filter:
  proc rstrip(value: VMValue): VMValue =
    if value.kind != vmString:
      return value
    var s = value.stringVal
    while s.len > 0 and s[^1] in {' ', '\t', '\n', '\r'}:
      s = s[0..^2]
    result = VMValue(kind: vmString, stringVal: s)

# Extracts a substring from a string
create_filter:
  proc slice(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmString:
      return value
    if args.len < 1:
      raise newException(ValueError, "slice filter requires at least 1 argument (start index)")
    if args.len > 2:
      raise newException(ValueError, "slice filter takes at most 2 arguments")
    
    let str = value.stringVal
    
    # Handle undefined first argument
    if args[0].kind == vmNull:
      raise newException(ValueError, "slice filter: first argument cannot be undefined")
    
    # Convert arguments to integers with proper validation
    var startIdx: int
    if args[0].kind == vmInt:
      startIdx = args[0].intVal.int
    elif args[0].kind == vmFloat:
      raise newException(ValueError, "slice filter: first argument must be an integer, not a float")
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
        length = 1  # undefined second argument defaults to 1
      elif args[1].kind == vmInt:
        length = args[1].intVal.int
      elif args[1].kind == vmFloat:
        raise newException(ValueError, "slice filter: second argument must be an integer, not a float")
      elif args[1].kind == vmString:
        try:
          length = args[1].stringVal.parseInt()
        except:
          raise newException(ValueError, "slice filter: second argument must be an integer")
      else:
        raise newException(ValueError, "slice filter: second argument must be an integer")
    
    # Handle negative indices
    let actualStart = if startIdx < 0: str.len + startIdx else: startIdx
    
    # Handle negative length - should return empty string
    if length <= 0:
      result = VMValue(kind: vmString, stringVal: "")
    elif actualStart < 0 or actualStart >= str.len:
      result = VMValue(kind: vmString, stringVal: "")
    else:
      let endIdx = min(actualStart + length, str.len)
      result = VMValue(kind: vmString, stringVal: str[actualStart..<endIdx])

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
  proc split(value: VMValue, delimiter: VMValue): VMValue =
    if value.kind != vmString:
      return VMValue(kind: vmArray, arrayVal: @[])
    
    let delim = getStringVal(delimiter)
    let parts = value.stringVal.split(delim)
    let vmParts = parts.mapIt(VMValue(kind: vmString, stringVal: it))
    result = VMValue(kind: vmArray, arrayVal: vmParts)