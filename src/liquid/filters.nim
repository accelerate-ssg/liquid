import tables

import shared, filters/[strings, arrays, numbers, dates, misc]

# VMValue version of apply_filter
proc apply_filter*(value: VMValue, filter_name: string, args: seq[VMValue]): VMValue =
  ## Apply a filter to a VMValue
  try:
    # Check if filter exists
    if filter_name notin shared.filters:
      echo "Unknown filter: ", filter_name
      return VMValue(kind: vmString, stringVal: "")
    
    # Get the filter function
    let filter = filters[filter_name]
    
    # Apply the filter (let each filter handle null values as appropriate)
    result = filter(value, args)
    
    # If the filter returns null, convert it to an empty string
    if result.kind == vmNull:
      result = VMValue(kind: vmString, stringVal: "")
    
  except CatchableError as e:
    echo "Error applying filter '" & filter_name & "': " & e.msg
    raise e  # Re-throw the exception so tests can catch it