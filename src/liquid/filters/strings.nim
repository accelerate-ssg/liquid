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
  proc append(value: VMValue, args: varargs[VMValue]): VMValue =
    if args.len != 1:
      raise newException(ValueError, "append filter requires exactly 1 argument")
    let input = getStringVal(value)
    let suffix = getStringVal(args[0])
    result = VMValue(kind: vmString, stringVal: input & suffix)

# Converts a string into a base64-decoded string
create_filter:
  proc base64_decode(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmString:
      return value
    result = VMValue(kind: vmString, stringVal: value.stringVal.decode())

# Converts a base64-encoded string into a string
create_filter:
  proc base64_encode(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmString:
      return value
    result = VMValue(kind: vmString, stringVal: value.stringVal.encode())

# Converts a string into a URL-safe base64-decoded string
create_filter:
  proc base64_url_safe_decode(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmString:
      return value
    result = VMValue(kind: vmString, stringVal: value.stringVal.decode())

# Converts a URL-safe base64-encoded string into a string
create_filter:
  proc base64_url_safe_encode(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmString:
      return value
    result = VMValue(kind: vmString, stringVal: value.stringVal.encode(safe = true))

# Capitalizes the first word in a string and downcases the remaining characters
create_filter:
  proc capitalize(value: VMValue, args: varargs[VMValue]): VMValue =
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
  proc downcase(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmString:
      return value
    result = VMValue(kind: vmString, stringVal: value.stringVal.toLower())

# escape - Escapes special characters in HTML
create_filter:
  proc escape(value: VMValue, args: varargs[VMValue]): VMValue =
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
  proc strip(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmString:
      return value
    result = VMValue(kind: vmString, stringVal: value.stringVal.strip())

# Returns the first N characters of a string
create_filter:
  proc truncate(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmString:
      return value
    
    if args.len < 1:
      raise newException(ValueError, "truncate filter requires at least 1 argument (length)")
    
    let length = if args[0].kind == vmInt: args[0].intVal.int else: 50
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
    
    if args.len < 1:
      raise newException(ValueError, "truncatewords filter requires at least 1 argument (word count)")
    
    let wordCount = if args[0].kind == vmInt: args[0].intVal.int else: 15
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
  proc upcase(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmString:
      return value
    result = VMValue(kind: vmString, stringVal: value.stringVal.toUpper())

# Prepends a string to another string
create_filter:
  proc prepend(value: VMValue, args: varargs[VMValue]): VMValue =
    if args.len != 1:
      raise newException(ValueError, "prepend filter requires exactly 1 argument")
    let input = getStringVal(value)
    let prefix = getStringVal(args[0])
    result = VMValue(kind: vmString, stringVal: prefix & input)

# Removes a substring from a string
create_filter:
  proc remove(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmString:
      return value
    if args.len != 1:
      raise newException(ValueError, "remove filter requires exactly 1 argument")
    let substring = getStringVal(args[0])
    result = VMValue(kind: vmString, stringVal: value.stringVal.replace(substring, ""))

# Removes the first occurrence of a substring from a string
create_filter:
  proc remove_first(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmString:
      return value
    if args.len != 1:
      raise newException(ValueError, "remove_first filter requires exactly 1 argument")
    let substring = getStringVal(args[0])
    let idx = value.stringVal.find(substring)
    var resultStr = value.stringVal
    if idx >= 0:
      resultStr = value.stringVal[0..<idx] & value.stringVal[idx + substring.len..^1]
    result = VMValue(kind: vmString, stringVal: resultStr)

# Replaces all occurrences of a substring with another string
create_filter:
  proc replace(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmString:
      return value
    if args.len != 2:
      raise newException(ValueError, "replace filter requires exactly 2 arguments")
    let search = getStringVal(args[0])
    let replacement = getStringVal(args[1])
    result = VMValue(kind: vmString, stringVal: value.stringVal.replace(search, replacement))

# Replaces the first occurrence of a substring with another string
create_filter:
  proc replace_first(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmString:
      return value
    if args.len != 2:
      raise newException(ValueError, "replace_first filter requires exactly 2 arguments")
    let search = getStringVal(args[0])
    let replacement = getStringVal(args[1])
    let idx = value.stringVal.find(search)
    var resultStr = value.stringVal
    if idx >= 0:
      resultStr = value.stringVal[0..<idx] & replacement & value.stringVal[idx + search.len..^1]
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