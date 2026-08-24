import std/[tables, hashes, algorithm, math, sets]

from ../compiler/types import Instruction, VMValue, VMValueKind
import arena_context_store

type
  # Tag runtime handler (forward declaration for LiquidVM)
  TagRuntimeHandler* = proc(vm: var LiquidVM, inst: Instruction) {.nimcall.}

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
    #
    # The caller's context, borrowed rather than owned. The VM only ever
    # reads through it, so a sub-VM for {% include %} shares the parent's
    # pointer instead of duplicating a table that can hold an entire site's
    # data. nil when there is no eager context (the arena path, or no data).
    # It is only valid for the render call it was passed to — a VM must
    # never outlive the data it borrows.
    context*: ptr Table[string, VMValue]
    # Lowest-priority scope the VM owns. Only {% render %} over a
    # collection writes here, to expose forloop without letting loops
    # inside the partial pick it up as their parentloop.
    variables*: Table[string, VMValue]
    locals*: Table[string, VMValue]     # Template-created variables

    # Arena-backed context: variable names miss the tables above and then
    # resolve against this root object. nil arena means no arena context.
    # Reads through it land in the arena's access log, which is the whole
    # point: the log is what incremental rebuilds consult.
    arena*: ptr Arena
    context_root*: NodeId
    
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
    # Partial sources, borrowed on the same terms as context: read-only for
    # the VM's lifetime, shared with every sub-VM. nil when none were given.
    partials*: ptr Table[string, string]
    partial_cache*: Table[string, tuple[bytecode: seq[Instruction], strings: seq[string], constants: seq[VMValue]]]

    # Break/continue propagation (for include tag)
    pending_break*: bool
    pending_continue*: bool

    # Keyword arguments (for include tag) - read-only overlay on locals
    keyword_args*: Table[string, VMValue]

    # Cycle tag counters
    cycle_counters*: Table[string, int]  # group_key -> current index

    # Increment/decrement counters (separate namespace from assign/capture)
    counters*: Table[string, int64]  # counter_name -> current value

    # Tablerow state
    tablerow_iters*: seq[TablerowState]  # Stack of active tablerow iterators

    # Ifchanged state
    ifchanged_last*: string  # Last output from ifchanged block

    # Blank check state (for whitespace-only block suppression)
    blank_check_stack*: seq[int]  # Stack of output positions to check

    # Tag runtime handlers (for externalized tag implementations)
    tag_handlers*: Table[string, TagRuntimeHandler]


    # Performance
    instruction_count*: int
    max_stack_size*: int
    
  TablerowState* = object
    items*: seq[VMValue]
    index*: int          # Current item index (0-based)
    cols*: int           # Number of columns (0 = unlimited)
    var_name*: string    # Loop variable name
    # Built on demand like forloop, and for the same reason: a tablerow
    # body that never mentions tablerowloop should not pay to describe it.
    tablerowloop_cache*: VMValue
    tablerowloop_valid*: bool

  Iterator* = object
    items*: seq[VMValue]
    index*: int
    var_name*: string
    original_offset*: int  # Offset applied to original collection (for offset: continue tracking)
    saved_forloop*: VMValue  # Saved forloop value from before this loop started (for nesting)
    loop_name*: string       # forloop.name value (e.g., "tag-product.tags")
    # forloop metadata is built on demand, not per iteration: most loop
    # bodies never mention it, and building the object cost more than the
    # rest of an iteration put together. Cleared when the iteration
    # advances, rebuilt at most once per iteration by the first lookup.
    forloop_cache*: VMValue
    forloop_valid*: bool
    


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
  of vmEmpty:
    return true  # All empty values are equal
  of vmNode:
    # Same node = same value. Two different nodes may hold equal data,
    # but callers that care (opEqual and friends) materialize before
    # comparing, so identity is the only meaning left here.
    return a.nodeVal == b.nodeVal

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
  of vmEmpty:
    discard  # All empty values hash the same
  of vmNode:
    h = h !& hash(v.nodeVal)

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
  of vmEmpty:
    return false  # empty is falsy like null
  of vmNode:
    # Emptiness would need arena access to tell; treat lazy containers
    # as truthy. (This helper currently has no callers.)
    return true

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

proc vm_object*(o: OrderedTable[string, VMValue]): VMValue =
  VMValue(kind: vm_object, objectVal: o)

proc vm_object*(o: Table[string, VMValue]): VMValue =
  var ordered = initOrderedTable[string, VMValue]()
  for k, v in o:
    ordered[k] = v
  VMValue(kind: vm_object, objectVal: ordered)
