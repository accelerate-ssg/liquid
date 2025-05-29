import json, strutils
import ../shared

# Returns the default value if the input is null, false, or empty
create_filter:
  proc default(input: JsonNode, defaultValue: JsonNode): JsonNode =
    case input.kind
    of JNull:
      result = defaultValue
    of JBool:
      if not input.getBool:
        result = defaultValue
      else:
        result = input
    of JString:
      if input.getStr == "":
        result = defaultValue
      else:
        result = input
    of JArray:
      if input.len == 0:
        result = defaultValue
      else:
        result = input
    else:
      result = input


# Returns a JSON string representation of the input
create_filter:
  proc json(input: JsonNode): string =
    result = $input

# For debugging - returns a string representation of the input
create_filter:
  proc inspect(input: JsonNode): string =
    result = $input

# Check if value is empty (null, false, empty string, empty array)
create_filter:
  proc empty(input: JsonNode): bool =
    case input.kind
    of JNull:
      result = true
    of JBool:
      result = not input.getBool
    of JString:
      result = input.getStr == ""
    of JArray:
      result = input.len == 0
    of JObject:
      result = input.len == 0
    else:
      result = false

# Check if value is blank (null, false, empty string, whitespace-only string, empty array)
create_filter:
  proc blank(input: JsonNode): bool =
    case input.kind
    of JNull:
      result = true
    of JBool:
      result = not input.getBool
    of JString:
      result = input.getStr.strip() == ""
    of JArray:
      result = input.len == 0
    of JObject:
      result = input.len == 0
    else:
      result = false

# Check if value is present (opposite of blank)
create_filter:
  proc present(input: JsonNode): bool =
    case input.kind
    of JNull:
      result = false
    of JBool:
      result = input.getBool
    of JString:
      result = input.getStr.strip() != ""
    of JArray:
      result = input.len > 0
    of JObject:
      result = input.len > 0
    else:
      result = true

# Returns the type of the input as a string
create_filter:
  proc type_of(input: JsonNode): string =
    case input.kind
    of JNull:
      result = "null"
    of JBool:
      result = "boolean"
    of JInt:
      result = "number"
    of JFloat:
      result = "number"
    of JString:
      result = "string"
    of JArray:
      result = "array"
    of JObject:
      result = "object"