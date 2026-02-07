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
    escape_html*: bool
    
    # Capture state for {% capture %} tags
    capture_stack*: seq[string]  # Stack of captured outputs
    capture_escape_stack*: seq[bool]  # Track escape state for nested captures
    is_capturing*: bool
    
    # Filters are now handled by the filters module

    # Loop continuation tracking (for offset: continue)
    loop_offsets*: Table[string, int]  # var_name -> last consumed index

    # Template partials (for include/render tags)
    partials*: Table[string, string]  # partial name -> source
    partial_cache*: Table[string, tuple[bytecode: seq[Instruction], strings: seq[string], constants: seq[VMValue]]]

    # Break/continue propagation (for include tag)
    pending_break*: bool
    pending_continue*: bool

    # Performance
    instruction_count*: int
    max_stack_size*: int
    
  Iterator* = object
    items*: seq[VMValue]
    index*: int
    var_name*: string
    original_offset*: int  # Offset applied to original collection (for offset: continue tracking)
    saved_forloop*: VMValue  # Saved forloop value from before this loop started (for nesting)
    


proc `==`*(a, b: VMValue): bool =
  ## Compare two VMValues for equality
  # First check if kinds match
  if a.kind != b.kind:
    return false
  
  # Then compare based on kind
  case a.kind
  of vm_null:
    return true  # All nulls are equal
  of vm_bool:
    return a.boolVal == b.boolVal
  of vm_int:
    return a.intVal == b.intVal
  of vm_float:
    return a.floatVal == b.floatVal
  of vm_string:
    return a.stringVal == b.stringVal
  of vm_array:
    if a.arrayVal.len != b.arrayVal.len:
      return false
    for i in 0..<a.arrayVal.len:
      if a.arrayVal[i] != b.arrayVal[i]:
        return false
    return true
  of vm_object:
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
  of vm_null:
    discard  # All nulls hash the same
  of vm_bool:
    h = h !& hash(v.boolVal)
  of vm_int:
    h = h !& hash(v.intVal)
  of vm_float:
    h = h !& hash(v.floatVal)
  of vm_string:
    h = h !& hash(v.stringVal)
  of vm_array:
    for item in v.arrayVal:
      h = h !& hash(item)
  of vm_object:
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
proc to_bool*(v: VMValue): bool =
  ## Convert VMValue to boolean (for truthiness)
  case v.kind
  of vm_null:
    return false
  of vm_bool:
    return v.boolVal
  of vm_int:
    return v.intVal != 0
  of vm_float:
    return v.floatVal != 0.0 and not v.floatVal.isNaN
  of vm_string:
    return v.stringVal.len > 0
  of vm_array:
    return v.arrayVal.len > 0
  of vm_object:
    return v.objectVal.len > 0
  of vmLazy, vmIterator:
    return true  # Functions/iterators are truthy

# Helper constructor functions for cleaner code
proc vm_null*(): VMValue =
  VMValue(kind: vm_null)

proc vm_bool*(b: bool): VMValue =
  VMValue(kind: vm_bool, boolVal: b)

proc vm_int*(i: int64): VMValue =
  VMValue(kind: vm_int, intVal: i)

proc vm_float*(f: float64): VMValue =
  VMValue(kind: vm_float, floatVal: f)

proc vm_string*(s: string): VMValue =
  VMValue(kind: vm_string, stringVal: s)

proc vm_array*(a: seq[VMValue]): VMValue =
  VMValue(kind: vm_array, arrayVal: a)

proc vm_object*(o: Table[string, VMValue]): VMValue =
  VMValue(kind: vm_object, objectVal: o)
