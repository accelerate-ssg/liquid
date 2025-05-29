import json, math
import ../shared

# Returns the absolute value of a number
create_filter:
  proc abs(input: JsonNode): JsonNode =
    case input.kind
    of JInt:
      result = newJInt(abs(input.getInt))
    of JFloat:
      result = newJFloat(abs(input.getFloat))
    else:
      result = input

# Rounds a number to the nearest integer or to a specified number of decimal places
create_filter:
  proc round(input: JsonNode, precision: int = 0): JsonNode =
    case input.kind
    of JInt:
      result = input  # Already an integer
    of JFloat:
      if precision == 0:
        result = newJInt(round(input.getFloat).int)
      else:
        let multiplier = pow(10.0, precision.float)
        result = newJFloat(round(input.getFloat * multiplier) / multiplier)
    else:
      result = input

# Rounds a number up to the nearest integer
create_filter:
  proc ceil(input: JsonNode): JsonNode =
    case input.kind
    of JInt:
      result = input
    of JFloat:
      result = newJInt(ceil(input.getFloat).int)
    else:
      result = input

# Rounds a number down to the nearest integer
create_filter:
  proc floor(input: JsonNode): JsonNode =
    case input.kind
    of JInt:
      result = input
    of JFloat:
      result = newJInt(floor(input.getFloat).int)
    else:
      result = input

# Adds two numbers together
create_filter:
  proc plus(input: JsonNode, value: JsonNode): JsonNode =
    case input.kind
    of JInt:
      case value.kind
      of JInt:
        result = newJInt(input.getInt + value.getInt)
      of JFloat:
        result = newJFloat(input.getInt.float + value.getFloat)
      else:
        result = input
    of JFloat:
      case value.kind
      of JInt:
        result = newJFloat(input.getFloat + value.getInt.float)
      of JFloat:
        result = newJFloat(input.getFloat + value.getFloat)
      else:
        result = input
    else:
      result = input

# Subtracts one number from another
create_filter:
  proc minus(input: JsonNode, value: JsonNode): JsonNode =
    case input.kind
    of JInt:
      case value.kind
      of JInt:
        result = newJInt(input.getInt - value.getInt)
      of JFloat:
        result = newJFloat(input.getInt.float - value.getFloat)
      else:
        result = input
    of JFloat:
      case value.kind
      of JInt:
        result = newJFloat(input.getFloat - value.getInt.float)
      of JFloat:
        result = newJFloat(input.getFloat - value.getFloat)
      else:
        result = input
    else:
      result = input

# Multiplies a number by another number
create_filter:
  proc times(input: JsonNode, value: JsonNode): JsonNode =
    case input.kind
    of JInt:
      case value.kind
      of JInt:
        result = newJInt(input.getInt * value.getInt)
      of JFloat:
        result = newJFloat(input.getInt.float * value.getFloat)
      else:
        result = input
    of JFloat:
      case value.kind
      of JInt:
        result = newJFloat(input.getFloat * value.getInt.float)
      of JFloat:
        result = newJFloat(input.getFloat * value.getFloat)
      else:
        result = input
    else:
      result = input

# Divides a number by another number
create_filter:
  proc divided_by(input: JsonNode, value: JsonNode): JsonNode =
    # Check for division by zero
    let isZero = case value.kind
      of JInt: value.getInt == 0
      of JFloat: value.getFloat == 0.0
      else: true
    
    if isZero:
      return newJNull()
    
    case input.kind
    of JInt:
      case value.kind
      of JInt:
        # Integer division in Liquid returns integer
        result = newJInt(input.getInt div value.getInt)
      of JFloat:
        result = newJFloat(input.getInt.float / value.getFloat)
      else:
        result = input
    of JFloat:
      case value.kind
      of JInt:
        result = newJFloat(input.getFloat / value.getInt.float)
      of JFloat:
        result = newJFloat(input.getFloat / value.getFloat)
      else:
        result = input
    else:
      result = input

# Returns the remainder of a division operation
create_filter:
  proc modulo(input: JsonNode, value: JsonNode): JsonNode =
    # Check for division by zero
    let isZero = case value.kind
      of JInt: value.getInt == 0
      of JFloat: value.getFloat == 0.0
      else: true
    
    if isZero:
      return newJNull()
    
    case input.kind
    of JInt:
      case value.kind
      of JInt:
        result = newJInt(input.getInt mod value.getInt)
      of JFloat:
        result = newJFloat(input.getInt.float mod value.getFloat)
      else:
        result = input
    of JFloat:
      case value.kind
      of JInt:
        result = newJFloat(input.getFloat mod value.getInt.float)
      of JFloat:
        result = newJFloat(input.getFloat mod value.getFloat)
      else:
        result = input
    else:
      result = input

# Limits a number to a minimum value
create_filter:
  proc at_least(input: JsonNode, minimum: JsonNode): JsonNode =
    case input.kind
    of JInt:
      case minimum.kind
      of JInt:
        result = newJInt(max(input.getInt, minimum.getInt))
      of JFloat:
        result = newJFloat(max(input.getInt.float, minimum.getFloat))
      else:
        result = input
    of JFloat:
      case minimum.kind
      of JInt:
        result = newJFloat(max(input.getFloat, minimum.getInt.float))
      of JFloat:
        result = newJFloat(max(input.getFloat, minimum.getFloat))
      else:
        result = input
    else:
      result = input

# Limits a number to a maximum value
create_filter:
  proc at_most(input: JsonNode, maximum: JsonNode): JsonNode =
    case input.kind
    of JInt:
      case maximum.kind
      of JInt:
        result = newJInt(min(input.getInt, maximum.getInt))
      of JFloat:
        result = newJFloat(min(input.getInt.float, maximum.getFloat))
      else:
        result = input
    of JFloat:
      case maximum.kind
      of JInt:
        result = newJFloat(min(input.getFloat, maximum.getInt.float))
      of JFloat:
        result = newJFloat(min(input.getFloat, maximum.getFloat))
      else:
        result = input
    else:
      result = input