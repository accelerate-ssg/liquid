import math, strutils
import ../shared

# Helper to get numeric value
proc getNumericVal(v: VMValue): float =
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
  proc abs(value: VMValue, args: varargs[VMValue]): VMValue =
    case value.kind
    of vmInt:
      result = VMValue(kind: vmInt, intVal: abs(value.intVal))
    of vmFloat:
      result = VMValue(kind: vmFloat, floatVal: abs(value.floatVal))
    else:
      result = value

# Returns the smallest integer greater than or equal to a number
create_filter:
  proc ceil(value: VMValue, args: varargs[VMValue]): VMValue =
    let num = getNumericVal(value)
    result = VMValue(kind: vmInt, intVal: ceil(num).int64)

# Returns the largest integer less than or equal to a number
create_filter:
  proc floor(value: VMValue, args: varargs[VMValue]): VMValue =
    let num = getNumericVal(value)
    result = VMValue(kind: vmInt, intVal: floor(num).int64)

# Rounds a number to the nearest integer
create_filter:
  proc round(value: VMValue, args: varargs[VMValue]): VMValue =
    let decimals = if args.len > 0 and args[0].kind == vmInt: 
      args[0].intVal.int 
    else: 
      0
    
    let num = getNumericVal(value)
    if decimals == 0:
      result = VMValue(kind: vmInt, intVal: round(num).int64)
    else:
      let multiplier = pow(10.0, decimals.float)
      let rounded = round(num * multiplier) / multiplier
      result = VMValue(kind: vmFloat, floatVal: rounded)

# Adds a number to another number
create_filter:
  proc plus(value: VMValue, args: varargs[VMValue]): VMValue =
    if args.len != 1:
      raise newException(ValueError, "plus filter requires exactly 1 argument")
    
    let a = getNumericVal(value)
    let b = getNumericVal(args[0])
    
    if value.kind == vmInt and args[0].kind == vmInt:
      result = VMValue(kind: vmInt, intVal: value.intVal + args[0].intVal)
    else:
      result = VMValue(kind: vmFloat, floatVal: a + b)

# Subtracts a number from another number
create_filter:
  proc minus(value: VMValue, args: varargs[VMValue]): VMValue =
    if args.len != 1:
      raise newException(ValueError, "minus filter requires exactly 1 argument")
    
    let a = getNumericVal(value)
    let b = getNumericVal(args[0])
    
    if value.kind == vmInt and args[0].kind == vmInt:
      result = VMValue(kind: vmInt, intVal: value.intVal - args[0].intVal)
    else:
      result = VMValue(kind: vmFloat, floatVal: a - b)

# Multiplies a number by another number
create_filter:
  proc times(value: VMValue, args: varargs[VMValue]): VMValue =
    if args.len != 1:
      raise newException(ValueError, "times filter requires exactly 1 argument")
    
    let a = getNumericVal(value)
    let b = getNumericVal(args[0])
    
    if value.kind == vmInt and args[0].kind == vmInt:
      result = VMValue(kind: vmInt, intVal: value.intVal * args[0].intVal)
    else:
      result = VMValue(kind: vmFloat, floatVal: a * b)

# Divides a number by another number
create_filter:
  proc divided_by(value: VMValue, args: varargs[VMValue]): VMValue =
    if args.len != 1:
      raise newException(ValueError, "divided_by filter requires exactly 1 argument")
    
    let a = getNumericVal(value)
    let b = getNumericVal(args[0])
    
    if b == 0:
      raise newException(ValueError, "Division by zero")
    
    # Integer division if both are integers
    if value.kind == vmInt and args[0].kind == vmInt:
      result = VMValue(kind: vmInt, intVal: value.intVal div args[0].intVal)
    else:
      result = VMValue(kind: vmFloat, floatVal: a / b)

# Returns the remainder of division
create_filter:
  proc modulo(value: VMValue, args: varargs[VMValue]): VMValue =
    if args.len != 1:
      raise newException(ValueError, "modulo filter requires exactly 1 argument")
    
    if value.kind == vmInt and args[0].kind == vmInt:
      if args[0].intVal == 0:
        raise newException(ValueError, "Modulo by zero")
      result = VMValue(kind: vmInt, intVal: value.intVal mod args[0].intVal)
    else:
      let a = getNumericVal(value)
      let b = getNumericVal(args[0])
      if b == 0:
        raise newException(ValueError, "Modulo by zero")
      result = VMValue(kind: vmFloat, floatVal: a.mod(b))

# Limits a number to a minimum value
create_filter:
  proc at_least(value: VMValue, args: varargs[VMValue]): VMValue =
    if args.len != 1:
      raise newException(ValueError, "at_least filter requires exactly 1 argument")
    
    let val = getNumericVal(value)
    let minVal = getNumericVal(args[0])
    
    if val < minVal:
      result = args[0]
    else:
      result = value

# Limits a number to a maximum value
create_filter:
  proc at_most(value: VMValue, args: varargs[VMValue]): VMValue =
    if args.len != 1:
      raise newException(ValueError, "at_most filter requires exactly 1 argument")
    
    let val = getNumericVal(value)
    let maxVal = getNumericVal(args[0])
    
    if val > maxVal:
      result = args[0]
    else:
      result = value