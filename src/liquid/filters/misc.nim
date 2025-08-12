import strutils, tables, sequtils
import ../shared

# Returns the default value if the input is null, false, or empty
create_filter:
  proc default(value: VMValue, defaultValue: VMValue): VMValue =
    let shouldUseDefault = case value.kind
    of vmNull:
      true
    of vmBool:
      not value.boolVal
    of vmString:
      value.stringVal == ""
    of vmArray:
      value.arrayVal.len == 0
    of vmObject:
      value.objectVal.len == 0
    else:
      false
    
    if shouldUseDefault:
      result = defaultValue
    else:
      result = value

# Returns a string representation of the input
create_filter:
  proc inspect(value: VMValue, args: varargs[VMValue]): VMValue =
    var inspected: string
    case value.kind
    of vmNull:
      inspected = "null"
    of vmBool:
      inspected = $value.boolVal
    of vmInt:
      inspected = $value.intVal
    of vmFloat:
      inspected = $value.floatVal
    of vmString:
      inspected = "\"" & value.stringVal & "\""
    of vmArray:
      var items: seq[string] = @[]
      for item in value.arrayVal:
        let itemStr = case item.kind
        of vmString: "\"" & item.stringVal & "\""
        of vmNull: "null"
        of vmBool: $item.boolVal
        of vmInt: $item.intVal
        of vmFloat: $item.floatVal
        else: "[object]"
        items.add(itemStr)
      inspected = "[" & items.join(", ") & "]"
    of vmObject:
      inspected = "{object}"
    else:
      inspected = "{unknown}"
    
    result = VMValue(kind: vmString, stringVal: inspected)

# Splits a string into an array
create_filter:
  proc split(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmString:
      return value
    
    let delimiter = if args.len > 0 and args[0].kind == vmString:
      args[0].stringVal
    else:
      " "
    
    let parts = value.stringVal.split(delimiter)
    var array: seq[VMValue] = @[]
    for part in parts:
      array.add(VMValue(kind: vmString, stringVal: part))
    
    result = VMValue(kind: vmArray, arrayVal: array)

# URL encodes a string
create_filter:
  proc url_encode(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmString:
      return value
    
    # Simple URL encoding - replace spaces and special chars
    var encoded = value.stringVal
    encoded = encoded.replace(" ", "%20")
    encoded = encoded.replace("&", "%26")
    encoded = encoded.replace("=", "%3D")
    encoded = encoded.replace("?", "%3F")
    encoded = encoded.replace("#", "%23")
    
    result = VMValue(kind: vmString, stringVal: encoded)

# URL decodes a string
create_filter:
  proc url_decode(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmString:
      return value
    
    # Simple URL decoding
    var decoded = value.stringVal
    decoded = decoded.replace("%20", " ")
    decoded = decoded.replace("%26", "&")
    decoded = decoded.replace("%3D", "=")
    decoded = decoded.replace("%3F", "?")
    decoded = decoded.replace("%23", "#")
    
    result = VMValue(kind: vmString, stringVal: decoded)

# Returns the type of the value as a string
create_filter:
  proc type_of(value: VMValue, args: varargs[VMValue]): VMValue =
    let typeName = case value.kind
    of vmNull: "null"
    of vmBool: "boolean"
    of vmInt: "number"
    of vmFloat: "number"
    of vmString: "string"
    of vmArray: "array"
    of vmObject: "object"
    else: "unknown"
    
    result = VMValue(kind: vmString, stringVal: typeName)

# Converts a value to JSON string
create_filter:
  proc json(value: VMValue, args: varargs[VMValue]): VMValue =
    proc toJson(v: VMValue): string =
      case v.kind
      of vmNull:
        "null"
      of vmBool:
        $v.boolVal
      of vmInt:
        $v.intVal
      of vmFloat:
        $v.floatVal
      of vmString:
        "\"" & v.stringVal.replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t") & "\""
      of vmArray:
        "[" & v.arrayVal.mapIt(toJson(it)).join(",") & "]"
      of vmObject:
        var pairs: seq[string] = @[]
        for k, v in v.objectVal:
          pairs.add("\"" & k & "\":" & toJson(v))
        "{" & pairs.join(",") & "}"
      else:
        "null"
    
    result = VMValue(kind: vmString, stringVal: toJson(value))

# URL encodes a string more comprehensively
create_filter:
  proc url_param_escape(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmString:
      return value
    
    var encoded = ""
    for c in value.stringVal:
      case c:
      of ' ': encoded.add("%20")
      of '!': encoded.add("%21")
      of '"': encoded.add("%22") 
      of '#': encoded.add("%23")
      of '$': encoded.add("%24")
      of '%': encoded.add("%25")
      of '&': encoded.add("%26")
      of '\'': encoded.add("%27")
      of '(': encoded.add("%28")
      of ')': encoded.add("%29")
      of '*': encoded.add("%2A")
      of '+': encoded.add("%2B")
      of ',': encoded.add("%2C")
      of '/': encoded.add("%2F")
      of ':': encoded.add("%3A")
      of ';': encoded.add("%3B")
      of '=': encoded.add("%3D")
      of '?': encoded.add("%3F")
      of '@': encoded.add("%40")
      of '[': encoded.add("%5B")
      of ']': encoded.add("%5D")
      else: encoded.add(c)
    
    result = VMValue(kind: vmString, stringVal: encoded)

# Escapes a string for use in URLs  
create_filter:
  proc url_escape(value: VMValue, args: varargs[VMValue]): VMValue =
    # This is essentially the same as url_encode but with different name for compatibility
    return url_encode(value, args)