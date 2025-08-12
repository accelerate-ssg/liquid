import json,tables

import shared, filters/[strings, arrays, numbers, dates, misc]
import compiler/[types, context_functions]

# Legacy JsonNode version for compatibility
proc applyFilter*(value: JsonNode, filterName: string, args: seq[JsonNode], context: Context): JsonNode =
  try:
    # Convert to VMValue and use the VM version
    let vmValue = jsonToVMValue(value)
    var vmArgs: seq[VMValue] = @[]
    for arg in args:
      vmArgs.add(jsonToVMValue(arg))
    
    # Directly call the filter instead of recursive call
    if filterName notin shared.filters:
      echo "Unknown filter: ", filterName
      result = newJString("")
      return
    
    let filter = shared.filters[filterName] 
    let vmResult = filter(vmValue, vmArgs)
    result = vmValueToJson(vmResult)

  except CatchableError as e:
    echo "Error applying filter '" & filterName & "': " & e.msg
    result = newJString("")

# Main VMValue version of applyFilter
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
    result = VMValue(kind: vmString, stringVal: "")