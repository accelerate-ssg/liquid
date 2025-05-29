import json, times, strutils
import ../shared

# Formats a date according to a specified format
# Liquid uses Ruby's strftime format
create_filter:
  proc date(input: string, format: string): string =
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
              return input  # Return original if can't parse
      
      # Convert Ruby strftime to Nim format
      var nimFormat = format
      
      # Common Ruby strftime conversions
      nimFormat = nimFormat.replace("%Y", "yyyy")  # 4-digit year
      nimFormat = nimFormat.replace("%y", "yy")    # 2-digit year
      nimFormat = nimFormat.replace("%m", "MM")    # Month as number
      nimFormat = nimFormat.replace("%B", "MMMM")  # Full month name
      nimFormat = nimFormat.replace("%b", "MMM")   # Abbreviated month name
      nimFormat = nimFormat.replace("%d", "dd")    # Day of month
      nimFormat = nimFormat.replace("%e", "d")     # Day of month (no leading zero)
      nimFormat = nimFormat.replace("%H", "HH")    # Hour (24-hour)
      nimFormat = nimFormat.replace("%I", "hh")    # Hour (12-hour)
      nimFormat = nimFormat.replace("%M", "mm")    # Minute
      nimFormat = nimFormat.replace("%S", "ss")    # Second
      nimFormat = nimFormat.replace("%p", "tt")    # AM/PM
      nimFormat = nimFormat.replace("%A", "dddd")  # Full weekday name
      nimFormat = nimFormat.replace("%a", "ddd")   # Abbreviated weekday name
      nimFormat = nimFormat.replace("%w", "e")     # Day of week (0-6)
      nimFormat = nimFormat.replace("%j", "DDD")   # Day of year
      nimFormat = nimFormat.replace("%U", "W")     # Week of year
      nimFormat = nimFormat.replace("%Z", "zzz")   # Time zone
      nimFormat = nimFormat.replace("%%", "%")     # Literal %
      
      # Special Liquid date formats
      case format:
      of "%c":
        nimFormat = "ddd MMM dd HH:mm:ss yyyy"
      of "%x":
        nimFormat = "MM/dd/yyyy"
      of "%X":
        nimFormat = "HH:mm:ss"
      of "%r":
        nimFormat = "hh:mm:ss tt"
      of "%R":
        nimFormat = "HH:mm"
      of "%T":
        nimFormat = "HH:mm:ss"
      of "%D":
        nimFormat = "MM/dd/yy"
      of "%F":
        nimFormat = "yyyy-MM-dd"
      else:
        discard
      
      result = dt.format(nimFormat)
    except:
      result = input