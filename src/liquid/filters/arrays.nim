import json, sequtils, algorithm, strutils
import ../shared

# Returns the first element of an array
create_filter:
  proc first(input: seq[JsonNode]): JsonNode =
    if input.len > 0:
      result = input[0]
    else:
      result = newJNull()

# Returns the last element of an array
create_filter:
  proc last(input: seq[JsonNode]): JsonNode =
    if input.len > 0:
      result = input[^1]
    else:
      result = newJNull()

# Joins the elements of an array into a string separated by a delimiter
create_filter:
  proc join(input: seq[JsonNode], delimiter: string = " "): string =
    result = input.mapIt(
      if it.kind == JString: it.getStr
      elif it.kind == JInt: $it.getInt
      elif it.kind == JFloat: $it.getFloat
      elif it.kind == JBool: $it.getBool
      else: $it
    ).join(delimiter)

# Returns the size of an array
create_filter:
  proc size(input: seq[JsonNode]): int =
    result = input.len

# Sorts an array in ascending order
create_filter:
  proc sort(input: seq[JsonNode]): seq[JsonNode] =
    result = input
    result.sort(proc(a, b: JsonNode): int =
      if a.kind == JString and b.kind == JString:
        return cmp(a.getStr, b.getStr)
      elif a.kind == JInt and b.kind == JInt:
        return cmp(a.getInt, b.getInt)
      elif a.kind == JFloat and b.kind == JFloat:
        return cmp(a.getFloat, b.getFloat)
      else:
        return 0
    )

# Sorts an array naturally (with proper number handling)
create_filter:
  proc sort_natural(input: seq[JsonNode]): seq[JsonNode] =
    result = input
    result.sort(proc(a, b: JsonNode): int =
      if a.kind == JString and b.kind == JString:
        # Natural sort implementation for strings with numbers
        let aStr = a.getStr
        let bStr = b.getStr
        var i = 0
        var j = 0
        
        while i < aStr.len and j < bStr.len:
          if aStr[i].isDigit and bStr[j].isDigit:
            # Compare numeric parts
            var aNum = 0
            var bNum = 0
            while i < aStr.len and aStr[i].isDigit:
              aNum = aNum * 10 + ord(aStr[i]) - ord('0')
              inc i
            while j < bStr.len and bStr[j].isDigit:
              bNum = bNum * 10 + ord(bStr[j]) - ord('0')
              inc j
            if aNum != bNum:
              return cmp(aNum, bNum)
          else:
            # Compare character by character
            if aStr[i] != bStr[j]:
              return cmp(aStr[i], bStr[j])
            inc i
            inc j
        
        return cmp(aStr.len, bStr.len)
      else:
        # Fall back to regular sort for non-strings
        return cmp($a, $b)
    )

# Reverses an array
create_filter:
  proc reverse(input: seq[JsonNode]): seq[JsonNode] =
    result = input
    result.reverse()

# Maps an array of objects to an array of values from a specified property
create_filter:
  proc map(input: seq[JsonNode], property: string): seq[JsonNode] =
    result = @[]
    for item in input:
      if item.kind == JObject and item.hasKey(property):
        result.add(item[property])
      else:
        result.add(newJNull())

# Removes duplicate elements from an array
create_filter:
  proc uniq(input: seq[JsonNode]): seq[JsonNode] =
    result = @[]
    for item in input:
      var found = false
      for existing in result:
        if $item == $existing:
          found = true
          break
      if not found:
        result.add(item)

# Returns a slice of an array
create_filter:
  proc slice(input: seq[JsonNode], start: int, length: int = -1): seq[JsonNode] =
    let actualStart = if start < 0: input.len + start else: start
    if actualStart < 0 or actualStart >= input.len:
      return @[]
    
    if length < 0:
      result = input[actualStart..^1]
    else:
      let endIdx = min(actualStart + length - 1, input.len - 1)
      result = input[actualStart..endIdx]

# Filters an array where a property equals a value
create_filter:
  proc where(input: seq[JsonNode], property: string, value: JsonNode = newJNull()): seq[JsonNode] =
    result = @[]
    for item in input:
      if item.kind == JObject and item.hasKey(property):
        if value.kind == JNull:
          # If no value specified, just check for truthy property
          let prop = item[property]
          if prop.kind != JNull and prop.kind != JBool or (prop.kind == JBool and prop.getBool):
            result.add(item)
        else:
          # Check if property equals value
          if $item[property] == $value:
            result.add(item)

# Concatenates arrays
create_filter:
  proc concat(input: seq[JsonNode], other: seq[JsonNode]): seq[JsonNode] =
    result = input & other

# Removes nil/null values from an array
create_filter:
  proc compact(input: seq[JsonNode]): seq[JsonNode] =
    result = @[]
    for item in input:
      if item.kind != JNull:
        result.add(item)

# Sum of all elements in an array
create_filter:
  proc sum(input: seq[JsonNode], property: string = ""): float =
    result = 0.0
    for item in input:
      if property != "" and item.kind == JObject and item.hasKey(property):
        let val = item[property]
        if val.kind == JInt:
          result += val.getInt.float
        elif val.kind == JFloat:
          result += val.getFloat
      else:
        if item.kind == JInt:
          result += item.getInt.float
        elif item.kind == JFloat:
          result += item.getFloat