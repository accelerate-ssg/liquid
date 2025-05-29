import json,tables

import shared, filters/[strings, arrays, numbers, dates, misc]


proc applyFilter*(value: JsonNode, filterName: string, args: seq[JsonNode], context: Context): JsonNode =
  try:
    if filterName notin shared.filters:
      echo "Unknown filter: ", filterName
      return newJString("")

    let filter = filters[filterName]
    
    # Handle null input
    if value.kind == JNull:
      return newJString("")

    # Apply the filter
    result = filter(value, args)

    # If the filter returns null, convert it to an empty string
    if result.kind == JNull:
      result = newJString("")

  except CatchableError as e:
    echo "Error applying filter '" & filterName & "': " & e.msg
    result = newJString("")
