import sequtils, algorithm, strutils, tables
import ../shared

# Helper to convert VMValue to string
proc toString(v: VMValue): string =
  case v.kind
  of vmString: v.stringVal
  of vmInt: $v.intVal
  of vmFloat: $v.floatVal
  of vmBool: $v.boolVal
  of vmNull: ""
  else: ""

# Returns the first element of an array
create_filter:
  proc first(value: VMValue): VMValue =
    if value.kind == vmArray and value.arrayVal.len > 0:
      result = value.arrayVal[0]
    else:
      result = VMValue(kind: vmNull)

# Returns the last element of an array
create_filter:
  proc last(value: VMValue): VMValue =
    if value.kind == vmArray and value.arrayVal.len > 0:
      result = value.arrayVal[^1]
    else:
      result = VMValue(kind: vmNull)

# Joins the elements of an array into a string separated by a delimiter
create_filter:
  proc join(value: VMValue, args: varargs[VMValue]): VMValue =
    if args.len > 1:
      raise newException(ValueError, "join filter takes at most 1 argument")
    if value.kind != vmArray:
      return value
    
    let delimiter = if args.len > 0 and args[0].kind == vmString:
      args[0].stringVal
    else:
      " "
    
    let joined = value.arrayVal.mapIt(toString(it)).join(delimiter)
    result = VMValue(kind: vmString, stringVal: joined)

# Returns the size of an array or string or object
create_filter:
  proc size(value: VMValue): VMValue =
    case value.kind
    of vmArray:
      result = VMValue(kind: vmInt, intVal: value.arrayVal.len.int64)
    of vmString:
      result = VMValue(kind: vmInt, intVal: value.stringVal.len.int64)
    of vmObject:
      result = VMValue(kind: vmInt, intVal: value.objectVal.len.int64)
    else:
      result = VMValue(kind: vmInt, intVal: 0)

# Sorts an array in ascending order
create_filter:
  proc sort(value: VMValue, args: varargs[VMValue]): VMValue =
    if args.len > 1:
      raise newException(ValueError, "sort filter takes at most 1 argument")
    if value.kind != vmArray:
      return value
    
    var sorted = value.arrayVal
    try:
      sorted.sort(proc(a, b: VMValue): int =
        # Compare based on types
        if a.kind == vmString and b.kind == vmString:
          return cmp(a.stringVal, b.stringVal)
        elif a.kind == vmInt and b.kind == vmInt:
          return cmp(a.intVal, b.intVal)
        elif a.kind == vmFloat and b.kind == vmFloat:
          return cmp(a.floatVal, b.floatVal)
        elif a.kind == vmBool and b.kind == vmBool:
          return cmp(a.boolVal, b.boolVal)
        # Mixed numeric types
        elif a.kind in [vmInt, vmFloat] and b.kind in [vmInt, vmFloat]:
          let aFloat = if a.kind == vmInt: a.intVal.float else: a.floatVal
          let bFloat = if b.kind == vmInt: b.intVal.float else: b.floatVal
          return cmp(aFloat, bFloat)
        else:
          # Different types - sort by string representation
          return cmp(toString(a), toString(b))
      )
    except:
      # Return original array if sorting fails (incompatible types)
      return value
    
    result = VMValue(kind: vmArray, arrayVal: sorted)

# Reverses an array
create_filter:
  proc reverse(value: VMValue, args: varargs[VMValue]): VMValue =
    if args.len > 0:
      raise newException(ValueError, "reverse filter takes no arguments")
    case value.kind
    of vmArray:
      var reversed = value.arrayVal
      reversed.reverse()
      result = VMValue(kind: vmArray, arrayVal: reversed)
    of vmString:
      var reversed = value.stringVal
      reversed.reverse()
      result = VMValue(kind: vmString, stringVal: reversed)
    else:
      result = value

# Maps an attribute from each object in an array
create_filter:
  proc map(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmArray:
      return value
    
    if args.len != 1 or args[0].kind != vmString:
      raise newException(ValueError, "map filter requires exactly 1 string argument (property name)")
    
    let propName = args[0].stringVal
    var mapped: seq[VMValue] = @[]
    
    for item in value.arrayVal:
      if item.kind == vmObject and propName in item.objectVal:
        mapped.add(item.objectVal[propName])
      else:
        mapped.add(VMValue(kind: vmNull))
    
    result = VMValue(kind: vmArray, arrayVal: mapped)

# Removes nil values from an array, optionally by property
create_filter:
  proc compact(value: VMValue, args: varargs[VMValue]): VMValue =
    # Check argument count first, regardless of value type
    if args.len > 1:
      raise newException(ValueError, "compact filter takes at most 1 argument")
    
    # If value is not an array, return it as-is
    if value.kind != vmArray:
      return value
    
    # If a property name is provided, compact based on that property
    if args.len == 1:
      if args[0].kind != vmString:
        return value
      let propName = args[0].stringVal
      var filtered: seq[VMValue]
      for item in value.arrayVal:
        if item.kind == vmObject and propName in item.objectVal:
          let propValue = item.objectVal[propName]
          if propValue.kind != vmNull:
            filtered.add(item)
        elif item.kind != vmObject:
          # Non-objects are kept if property filtering is used
          filtered.add(item)
      result = VMValue(kind: vmArray, arrayVal: filtered)
    else:
      # No property name - just remove null values
      let filtered = value.arrayVal.filterIt(it.kind != vmNull)
      result = VMValue(kind: vmArray, arrayVal: filtered)

# Concatenates arrays
create_filter:
  proc concat(value: VMValue, args: varargs[VMValue]): VMValue =
    # Require at least one argument
    if args.len == 0:
      raise newException(ValueError, "concat filter requires at least 1 argument")
    
    # Check all arguments are arrays or null
    for i, arg in args:
      if arg.kind == vmNull:
        raise newException(ValueError, "concat filter argument is undefined or null")
      elif arg.kind != vmArray:
        raise newException(ValueError, "concat filter arguments must be arrays")
    
    if value.kind != vmArray:
      return value
    
    var concatenated = value.arrayVal
    for arg in args:
      if arg.kind == vmArray:
        concatenated.add(arg.arrayVal)
    
    result = VMValue(kind: vmArray, arrayVal: concatenated)

# Returns unique elements from an array
create_filter:
  proc uniq(value: VMValue, args: varargs[VMValue]): VMValue =
    if args.len > 1:
      raise newException(ValueError, "uniq filter takes at most 1 argument")
    
    if value.kind != vmArray:
      return value
    
    var unique: seq[VMValue] = @[]
    
    for item in value.arrayVal:
      var found = false
      for existing in unique:
        # Manual comparison to avoid case object equality issues
        if item.kind == existing.kind:
          case item.kind
          of vmNull:
            found = true
            break
          of vmBool:
            if item.boolVal == existing.boolVal:
              found = true
              break
          of vmInt:
            if item.intVal == existing.intVal:
              found = true
              break
          of vmFloat:
            if item.floatVal == existing.floatVal:
              found = true
              break
          of vmString:
            if item.stringVal == existing.stringVal:
              found = true
              break
          else:
            # For arrays and objects, just consider them not equal for now
            discard
      
      if not found:
        unique.add(item)
    
    result = VMValue(kind: vmArray, arrayVal: unique)

# Filters array based on a property value
create_filter:
  proc where(value: VMValue, args: varargs[VMValue]): VMValue =
    # Check for empty or undefined value first
    if value.kind == vmNull:
      return VMValue(kind: vmArray, arrayVal: @[])
      
    if value.kind != vmArray:
      raise newException(ValueError, "where filter can only be applied to arrays")
    
    if args.len > 2:
      raise newException(ValueError, "where filter takes at most 2 arguments")
    
    if args.len < 1:
      raise newException(ValueError, "where filter requires at least 1 argument (property name)")
      
    # Handle undefined/null first argument
    if args[0].kind == vmNull:
      return VMValue(kind: vmArray, arrayVal: @[])
    
    if args[0].kind != vmString:
      raise newException(ValueError, "where filter requires at least 1 argument (property name)")
    
    let propName = args[0].stringVal
    
    if args.len == 1:
      # Filter for objects that have the property (non-null)
      let filtered = value.arrayVal.filterIt(
        it.kind == vmObject and 
        propName in it.objectVal and 
        it.objectVal[propName].kind != vmNull
      )
      result = VMValue(kind: vmArray, arrayVal: filtered)
    else:
      # Filter for objects where property equals value  
      let propValue = args[1]
      var filtered: seq[VMValue] = @[]
      for item in value.arrayVal:
        if item.kind == vmObject and propName in item.objectVal:
          let itemPropValue = item.objectVal[propName]
          var matches = false
          if itemPropValue.kind == propValue.kind:
            case itemPropValue.kind
            of vmNull:
              matches = true
            of vmBool:
              matches = itemPropValue.boolVal == propValue.boolVal
            of vmInt:
              matches = itemPropValue.intVal == propValue.intVal
            of vmFloat:
              matches = itemPropValue.floatVal == propValue.floatVal
            of vmString:
              matches = itemPropValue.stringVal == propValue.stringVal
            else:
              matches = false
          if matches:
            filtered.add(item)
      result = VMValue(kind: vmArray, arrayVal: filtered)

# Sorts an array by a property of each element
create_filter:
  proc sort_by(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmArray:
      return value
    
    if args.len != 1 or args[0].kind != vmString:
      raise newException(ValueError, "sort_by filter requires exactly 1 string argument (property name)")
    
    let propName = args[0].stringVal
    var sorted = value.arrayVal
    
    sorted.sort(proc(a, b: VMValue): int =
      var aVal, bVal: VMValue
      if a.kind == vmObject and propName in a.objectVal:
        aVal = a.objectVal[propName]
      else:
        aVal = VMValue(kind: vmNull)
      
      if b.kind == vmObject and propName in b.objectVal:
        bVal = b.objectVal[propName]
      else:
        bVal = VMValue(kind: vmNull)
      
      # Compare based on types
      if aVal.kind == vmString and bVal.kind == vmString:
        return cmp(aVal.stringVal, bVal.stringVal)
      elif aVal.kind == vmInt and bVal.kind == vmInt:
        return cmp(aVal.intVal, bVal.intVal)
      elif aVal.kind == vmFloat and bVal.kind == vmFloat:
        return cmp(aVal.floatVal, bVal.floatVal)
      else:
        return cmp(toString(aVal), toString(bVal))
    )
    
    result = VMValue(kind: vmArray, arrayVal: sorted)

# Sorts an array using natural sort order
create_filter:
  proc sort_natural(value: VMValue, args: varargs[VMValue]): VMValue =
    if value.kind != vmArray:
      return value
    
    # For simplicity, this is the same as regular sort for now
    # A proper natural sort would handle numbers within strings differently
    var sorted = value.arrayVal
    sorted.sort(proc(a, b: VMValue): int =
      return cmp(toString(a).toLower(), toString(b).toLower())
    )
    
    result = VMValue(kind: vmArray, arrayVal: sorted)

# Sums all numeric values in an array
create_filter:
  proc sum(value: VMValue, args: varargs[VMValue]): VMValue =
    if args.len > 1:
      raise newException(ValueError, "sum filter takes at most 1 argument")
    if value.kind != vmArray:
      return VMValue(kind: vmInt, intVal: 0)
    
    let propName = if args.len > 0 and args[0].kind == vmString: args[0].stringVal else: ""
    
    var sumInt: int64 = 0
    var sumFloat: float64 = 0.0
    var hasFloat = false
    
    for item in value.arrayVal:
      var val = item
      
      # If property name specified, extract that property
      if propName != "":
        if val.kind == vmObject and propName in val.objectVal:
          val = val.objectVal[propName]
        else:
          continue  # Skip if property doesn't exist
      
      case val.kind
      of vmInt:
        sumInt += val.intVal
        sumFloat += val.intVal.float
      of vmFloat:
        hasFloat = true
        sumFloat += val.floatVal
      of vmString:
        try:
          if '.' in val.stringVal:
            hasFloat = true
            sumFloat += val.stringVal.parseFloat()
          else:
            let intVal = val.stringVal.parseInt()
            sumInt += intVal
            sumFloat += intVal.float
        except:
          continue  # Skip non-numeric strings
      else:
        continue  # Skip non-numeric values
    
    if hasFloat:
      result = VMValue(kind: vmFloat, floatVal: sumFloat)
    else:
      result = VMValue(kind: vmInt, intVal: sumInt)