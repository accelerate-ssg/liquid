import tables

import values

# VMValue version of apply_filter
proc apply_filter*(value: VMValue, filter_name: string, args: seq[VMValue]): VMValue =
  ## Apply a filter to a VMValue. Raises on filter errors.
  ## An unknown filter renders as the empty string.
  ##
  ## One probe of the registry, not two: `notin` followed by `[]` hashed
  ## the name and walked the table twice for every filter call.
  values.filters.withValue(filter_name, handler):
    result = handler[](value, args)
    # A filter returning null renders as the empty string
    if result.kind == vmNull:
      result = VMValue(kind: vmString, stringVal: "")
    return
  VMValue(kind: vmString, stringVal: "")
