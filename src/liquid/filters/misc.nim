import strutils, tables, sequtils
import ../shared

# Returns the default value if the input is null, false, or empty
create_filter:
  proc default(value: VMValue, args: varargs[VMValue]): VMValue =
    # Handle missing argument case
    if args.len == 0:
      return value
    
    # Validate maximum arguments (1 default value + 2 for allow_false keyword = 3 max)
    if args.len > 3:
      raise newException(ValueError, "default filter takes at most 1 positional argument and 1 keyword argument")
    
    # Default filter supports:
    # - default: 'value' (simple positional)
    # - default: 'value', allow_false: true (positional then keyword)  
    # - default: allow_false: true, 'value' (keyword then positional)
    #
    # When compiled, keyword arguments appear as consecutive args:
    # "allow_false", true (identifier string followed by value)
    
    var defaultValue = VMValue(kind: vmNull)
    var allowFalse = false
    var hasDefault = false
    var positionalCount = 0
    
    # Process arguments - args are pushed in reverse order by VM
    # So we need to process them in reverse
    var processedArgs: seq[VMValue] = @[]
    for i in countdown(args.len - 1, 0):
      processedArgs.add(args[i])
    
    var i = 0
    while i < processedArgs.len:
      # Check if this looks like the allow_false keyword argument
      # The pattern is: string "allow_false" followed by its value
      if i + 1 < processedArgs.len and 
         processedArgs[i].kind == vmString and 
         processedArgs[i].stringVal == "allow_false":
        # Skip the "allow_false" string and get its value
        i += 1
        allowFalse = case processedArgs[i].kind
          of vmBool: processedArgs[i].boolVal
          of vmNull: false
          else: true  # Treat any non-null value as truthy
        i += 1
      else:
        # Regular positional argument for default value
        positionalCount += 1
        if positionalCount > 1:
          raise newException(ValueError, "default filter takes too many arguments")
        if not hasDefault:
          defaultValue = processedArgs[i]
          hasDefault = true
        i += 1
    
    # If no default value was provided, return original
    if not hasDefault:
      return value
    
    # Determine if we should use the default value
    let shouldUseDefault = case value.kind
    of vmNull:
      true
    of vmBool:
      if allowFalse:
        false  # When allow_false is true, false is not considered falsy
      else:
        not value.boolVal  # Normal behavior: false is falsy
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