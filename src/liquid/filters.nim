import tables

import shared, filters/[strings, arrays, numbers, dates, misc]

# VMValue version of applyFilter
proc applyFilter*(value: VMValue, filterName: string, args: seq[VMValue]): VMValue =
  ## Apply a filter to a VMValue
  try:
    # Check if filter exists
    if filterName notin shared.filters:
      echo "Unknown filter: ", filterName
      return VMValue(kind: vmString, stringVal: "")
    
    # Get the filter function
    let filter = filters[filterName]
    
    # Handle null input - most filters should pass through null
    if value.kind == vmNull and filterName != "default":
      return VMValue(kind: vmString, stringVal: "")
    
    # Apply the filter
    result = filter(value, args)
    
    # If the filter returns null, convert it to an empty string
    if result.kind == vmNull:
      result = VMValue(kind: vmString, stringVal: "")
    
  except CatchableError as e:
    echo "Error applying filter '" & filterName & "': " & e.msg
    raise e  # Re-throw the exception so tests can catch it