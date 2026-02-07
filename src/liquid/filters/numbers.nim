import math, strutils
import ../shared

# Helper to get numeric value
proc to_numeric(v: VMValue): float =
  case v.kind
  of vmInt: v.intVal.float
  of vmFloat: v.floatVal
  of vmString:
    try:
      v.stringVal.parseFloat()
    except:
      0.0
  else: 0.0

# Returns the absolute value of a number
create_filter:
  proc abs(value: VMValue): VMValue =
    case value.kind
    of vmInt:
      result = VMValue(kind: vmInt, intVal: abs(value.intVal))
    of vmFloat:
      result = VMValue(kind: vmFloat, floatVal: abs(value.floatVal))
    of vmString:
      # Handle string numbers like Liquid does
      try:
        if '.' in value.stringVal:
          let floatVal = value.stringVal.parseFloat()
          result = VMValue(kind: vmFloat, floatVal: abs(floatVal))
        else:
          let intVal = value.stringVal.parseInt()
          result = VMValue(kind: vmInt, intVal: abs(intVal.int64))
      except:
        result = VMValue(kind: vmInt, intVal: 0)
    else:
      result = VMValue(kind: vmInt, intVal: 0)

# Returns the smallest integer greater than or equal to a number
create_filter:
  proc ceil(value: VMValue): VMValue =
    let num = to_numeric(value)
    result = VMValue(kind: vmInt, intVal: ceil(num).int64)

# Returns the largest integer less than or equal to a number
create_filter:
  proc floor(value: VMValue): VMValue =
    let num = to_numeric(value)
    result = VMValue(kind: vmInt, intVal: floor(num).int64)

# Rounds a number to the nearest integer
create_filter:
  proc round(value: VMValue, args: varargs[VMValue]): VMValue =
    if args.len > 1:
      raise newException(ValueError, "round filter takes at most 1 argument")
    
    let decimals = if args.len > 0 and args[0].kind == vmInt: 
      args[0].intVal.int 
    else: 
      0
    
    let num = to_numeric(value)
    if decimals == 0:
      result = VMValue(kind: vmInt, intVal: round(num).int64)
    else:
      let multiplier = pow(10.0, decimals.float)
      let rounded = round(num * multiplier) / multiplier
      result = VMValue(kind: vmFloat, floatVal: rounded)

# Adds a number to another number
create_filter:
  proc plus(value: VMValue, addend: VMValue): VMValue =
    let a = to_numeric(value)
    let b = to_numeric(addend)
    
    if value.kind == vmInt and addend.kind == vmInt:
      result = VMValue(kind: vmInt, intVal: value.intVal + addend.intVal)
    else:
      result = VMValue(kind: vmFloat, floatVal: a + b)

# Subtracts a number from another number
create_filter:
  proc minus(value: VMValue, subtrahend: VMValue): VMValue =
    let a = to_numeric(value)
    let b = to_numeric(subtrahend)
    
    if value.kind == vmInt and subtrahend.kind == vmInt:
      result = VMValue(kind: vmInt, intVal: value.intVal - subtrahend.intVal)
    else:
      result = VMValue(kind: vmFloat, floatVal: a - b)

# Multiplies a number by another number
create_filter:
  proc times(value: VMValue, multiplier: VMValue): VMValue =
    let a = to_numeric(value)
    let b = to_numeric(multiplier)
    
    if value.kind == vmInt and multiplier.kind == vmInt:
      result = VMValue(kind: vmInt, intVal: value.intVal * multiplier.intVal)
    else:
      result = VMValue(kind: vmFloat, floatVal: a * b)

# Divides a number by another number
create_filter:
  proc divided_by(value: VMValue, divisor: VMValue): VMValue =
    let a = to_numeric(value)
    let b = to_numeric(divisor)
    
    if b == 0:
      raise newException(ValueError, "Division by zero")
    
    # Integer division if both are integers
    if value.kind == vmInt and divisor.kind == vmInt:
      result = VMValue(kind: vmInt, intVal: value.intVal div divisor.intVal)
    else:
      result = VMValue(kind: vmFloat, floatVal: a / b)

# Returns the remainder of division
create_filter:
  proc modulo(value: VMValue, divisor: VMValue): VMValue =
    let a = to_numeric(value)
    let b = to_numeric(divisor)
    
    # Check if divisor is undefined (converted to 0 by to_numeric)
    if divisor.kind == vmNull:
      raise newException(ValueError, "Modulo by zero")
    
    if b == 0:
      raise newException(ValueError, "Modulo by zero")
    
    if value.kind == vmInt and divisor.kind == vmInt:
      result = VMValue(kind: vmInt, intVal: value.intVal mod divisor.intVal)
    else:
      result = VMValue(kind: vmFloat, floatVal: a.mod(b))

# Limits a number to a minimum value
create_filter:
  proc at_least(value: VMValue, minVal: VMValue): VMValue =
    let val = to_numeric(value)
    let minValue = to_numeric(minVal)
    
    if val < minValue:
      result = minVal
    else:
      result = value

# Limits a number to a maximum value
create_filter:
  proc at_most(value: VMValue, maxVal: VMValue): VMValue =
    let val = to_numeric(value)
    let maxValue = to_numeric(maxVal)
    
    if val > maxValue:
      result = maxVal
    else:
      result = value