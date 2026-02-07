import std/[tables, hashes, algorithm, math]

from ../compiler/types import Instruction, VMValue

type
  # Runtime VM for executing templates
  LiquidVM* = object
    # Execution state
    stack*: seq[VMValue]
    pc*: int                    # Program counter
    
    # The compiled template being executed
    bytecode*: seq[Instruction]
    strings*: seq[string]       # String constants
    constants*: seq[VMValue]    # Other constants
    
    # Runtime data
    variables*: Table[string, VMValue]  # User-provided data
    locals*: Table[string, VMValue]     # Template-created variables
    
    # Iteration state
    iterators*: seq[Iterator]   # Stack of active iterators
    
    # Output
    output*: string
    escapeHtml*: bool
    
    # Capture state for {% capture %} tags
    captureStack*: seq[string]  # Stack of captured outputs
    captureEscapeStack*: seq[bool]  # Track escape state for nested captures
    isCapturing*: bool
    
    # Filters are now handled by the filters module
    
    # Performance
    instructionCount*: int
    maxStackSize*: int
    
  Iterator* = object
    items*: seq[VMValue]
    index*: int
    varName*: string
    


proc `==`*(a, b: VMValue): bool =
  ## Compare two VMValues for equality
  # First check if kinds match
  if a.kind != b.kind:
    return false
  
  # Then compare based on kind
  case a.kind
  of vmNull:
    return true  # All nulls are equal
  of vmBool:
    return a.boolVal == b.boolVal
  of vmInt:
    return a.intVal == b.intVal
  of vmFloat:
    return a.floatVal == b.floatVal
  of vmString:
    return a.stringVal == b.stringVal
  of vmArray:
    if a.arrayVal.len != b.arrayVal.len:
      return false
    for i in 0..<a.arrayVal.len:
      if a.arrayVal[i] != b.arrayVal[i]:
        return false
    return true
  of vmObject:
    if a.objectVal.len != b.objectVal.len:
      return false
    for key, aVal in a.objectVal:
      if key notin b.objectVal:
        return false
      if aVal != b.objectVal[key]:
        return false
    return true
  of vmLazy:
    # Lazy values can't be compared directly
    return false
  of vmIterator:
    # Iterators can't be compared directly
    return false

# You might also want to add hash for using VMValue in tables
proc hash*(v: VMValue): Hash =
  ## Hash a VMValue for use in tables/sets
  var h: Hash = 0
  h = h !& hash(v.kind.int)
  
  case v.kind
  of vmNull:
    discard  # All nulls hash the same
  of vmBool:
    h = h !& hash(v.boolVal)
  of vmInt:
    h = h !& hash(v.intVal)
  of vmFloat:
    h = h !& hash(v.floatVal)
  of vmString:
    h = h !& hash(v.stringVal)
  of vmArray:
    for item in v.arrayVal:
      h = h !& hash(item)
  of vmObject:
    # Hash based on sorted keys for consistency
    var keys: seq[string] = @[]
    for k in v.objectVal.keys:
      keys.add(k)
    keys.sort()
    for k in keys:
      h = h !& hash(k)
      h = h !& hash(v.objectVal[k])
  of vmLazy, vmIterator:
    # Can't hash functions reliably
    h = h !& hash(cast[int](unsafeAddr v))
  
  result = !$h

# Also useful: conversion to bool for truthiness checks
proc toBool*(v: VMValue): bool =
  ## Convert VMValue to boolean (for truthiness)
  case v.kind
  of vmNull:
    return false
  of vmBool:
    return v.boolVal
  of vmInt:
    return v.intVal != 0
  of vmFloat:
    return v.floatVal != 0.0 and not v.floatVal.isNaN
  of vmString:
    return v.stringVal.len > 0
  of vmArray:
    return v.arrayVal.len > 0
  of vmObject:
    return v.objectVal.len > 0
  of vmLazy, vmIterator:
    return true  # Functions/iterators are truthy

# Helper constructor functions for cleaner code
proc vmNull*(): VMValue =
  VMValue(kind: vmNull)

proc vmBool*(b: bool): VMValue =
  VMValue(kind: vmBool, boolVal: b)

proc vmInt*(i: int64): VMValue =
  VMValue(kind: vmInt, intVal: i)

proc vmFloat*(f: float64): VMValue =
  VMValue(kind: vmFloat, floatVal: f)

proc vmString*(s: string): VMValue =
  VMValue(kind: vmString, stringVal: s)

proc vmArray*(a: seq[VMValue]): VMValue =
  VMValue(kind: vmArray, arrayVal: a)

proc vmObject*(o: Table[string, VMValue]): VMValue =
  VMValue(kind: vmObject, objectVal: o)
