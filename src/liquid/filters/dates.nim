import times, strutils
import ../shared

# Formats a date according to a specified format
create_filter:
  proc date(value: VMValue, args: varargs[VMValue]): VMValue =
    if args.len < 1:
      raise newException(ValueError, "date filter requires 1 argument (format)")
    
    let format = if args[0].kind == vmString:
      args[0].stringVal
    else:
      "%Y-%m-%d"
    
    var input: string
    case value.kind
    of vmString:
      input = value.stringVal
    of vmInt:
      # Treat as Unix timestamp
      try:
        let dt = fromUnix(value.intVal).local
        result = VMValue(kind: vmString, stringVal: dt.format(format))
        return
      except:
        result = value
        return
    else:
      result = value
      return
    
    try:
      # Parse various date formats
      var dt: DateTime
      
      # Try parsing ISO 8601 format first
      try:
        dt = parse(input, "yyyy-MM-dd'T'HH:mm:sszzz")
      except:
        try:
          dt = parse(input, "yyyy-MM-dd HH:mm:ss")
        except:
          try:
            dt = parse(input, "yyyy-MM-dd")
          except:
            # Try Unix timestamp
            try:
              let timestamp = parseInt(input)
              dt = fromUnix(timestamp).local
            except:
              # Return original if can't parse
              result = value
              return
      
      # Format the date
      let formatted = dt.format(format)
      result = VMValue(kind: vmString, stringVal: formatted)
    except:
      result = value

# Returns the current date/time
create_filter:
  proc date_now(value: VMValue, args: varargs[VMValue]): VMValue =
    let format = if args.len > 0 and args[0].kind == vmString:
      args[0].stringVal
    else:
      "%Y-%m-%d %H:%M:%S"
    
    let now = now()
    result = VMValue(kind: vmString, stringVal: now.format(format))