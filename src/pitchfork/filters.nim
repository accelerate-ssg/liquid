import tables

import values

# VMValue version of apply_filter
proc apply_filter*(value: VMValue, filter_name: string, args: seq[VMValue]): VMValue =
  ## Apply a filter to a VMValue. Raises on filter errors.
  # Check if filter exists
  if filter_name notin values.filters:
    return VMValue(kind: vmString, stringVal: "")

  # Get the filter function and apply it
  let filter = filters[filter_name]
  result = filter(value, args)

  # If the filter returns null, convert it to an empty string
  if result.kind == vmNull:
    result = VMValue(kind: vmString, stringVal: "")
