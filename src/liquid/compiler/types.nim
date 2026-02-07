import std/[tables, times, sets]

import ../types

type
  # Bytecode Instructions - Universal for all template languages
  OpCode* = enum
    # Stack Operations
    opPushNull           # Push null
    opPushTrue           # Push true
    opPushFalse          # Push false
    opPushEmpty          # Push empty (special value for empty comparisons)
    opPushInt            # Push int constant: [int64]
    opPushFloat          # Push float constant: [float64]
    opPushString         # Push string from constant pool: [stringId]
    opPop                # Pop and discard
    opDup                # Duplicate top of stack
    opSwap               # Swap top two items
    
    # Variable Operations
    opLoadVar            # Load variable: [stringId]
    opStoreVar           # Store to variable: [stringId]
    opLoadLocal          # Load local variable: [localIndex]
    opStoreLocal         # Store local: [localIndex]
    opLoadUpvalue        # Load from closure: [upvalueIndex]
    
    # Property/Index Access
    opGetProp            # Get property: [stringId]
    opSetProp            # Set property: [stringId]
    opGetIndex           # Get array/object index (key on stack)
    opSetIndex           # Set array/object index
    
    # Output Operations
    opOutput             # Output top of stack
    opOutputRaw          # Output without escaping
    opConcat             # Concatenate top N items: [count]
    opBeginCapture       # Start capturing output: [captureId]
    opEndCapture         # End capture and store: [varId]
    
    # Control Flow
    opJump               # Unconditional jump: [offset]
    opJumpIfFalse        # Jump if false: [offset]
    opJumpIfTrue         # Jump if true: [offset]
    opJumpIfNull         # Jump if null: [offset]
    opJumpIfEqual        # Jump if top 2 equal: [offset]
    
    # Loops - Critical for templates
    opBeginLoop          # Start loop: [localIndex for iterator]
    opIterNext           # Get next item, jump if done: [endOffset]
    opBreak              # Break from loop: [levels]
    opContinue           # Continue loop: [levels]

    # Comparison
    opEqual              # ==
    opNotEqual           # !=
    opLess               # <
    opLessEqual          # <=
    opGreater            # >
    opGreaterEqual       # >=
    opContains           # in/contains operator
    
    # Arithmetic
    opAdd                # +
    opSubtract           # -
    opMultiply           # *
    opDivide             # /
    opModulo             # %
    opNegate             # Unary -
    
    # Logic
    opAnd                # Logical AND (short-circuit)
    opOr                 # Logical OR (short-circuit)
    opNot                # Logical NOT
    
    # Functions/Filters
    opCall               # Call function: [argCount]
    opCallFilter         # Call filter: [filterId, argCount]
    opCallTag            # Call custom tag: [tagId, argCount]
    opReturn             # Return from function
    
    # Template Operations
    opInclude            # Include template: [templateId, withContext]
    opExtends            # Extend template: [templateId]
    opBlock              # Define/override block: [blockId]
    opSuper              # Call parent block
    opMacro              # Define macro: [macroId, paramCount]
    opCallMacro          # Call macro: [macroId, argCount]
    
    # Cycle tag
    opCycle              # Cycle through values: [groupId, argCount, values on stack]

    # Tablerow tag
    opTablerowBegin      # Start tablerow loop: sets up iterator and outputs initial HTML
    opTablerowIter       # Tablerow iteration: outputs </td>, handles row wrapping, loops or ends

    # Special Operations
    opTypeCheck          # Check value type: [expectedType]
    opCoerce             # Coerce to type: [targetType]
    opRange              # Create range: start..end on stack
    opSlice              # Slice array/string: [start, end]
    
    # Performance Optimizations
    opLoadConstant       # Load from constant pool: [constId]
    opBatchOutput        # Output multiple constants: [count, id1, id2, ...]
    opFastPath           # Optimized common patterns: [pathType]

  # Instruction with operands
  Instruction* = object
    # Use union-like structure for different operand types
    case op*: OpCode
    of opPushInt:
      intVal*: int64
    of opPushFloat:
      floatVal*: float64
    of opPushString, opLoadVar, opStoreVar, opGetProp, opSetProp:
      stringId*: uint32
    of opLoadLocal, opStoreLocal, opLoadUpvalue:
      index*: uint16
    of opJump, opJumpIfFalse, opJumpIfTrue, opJumpIfNull, opJumpIfEqual:
      offset*: int32
    of opCall, opConcat:
      count*: uint8
    of opCallFilter:
      filterId*: uint32
      argCount*: uint8
    of opCallTag:
      tagId*: uint32
      tagArgCount*: uint8
    of opInclude:
      templateId*: uint32        # String ID of the partial name
      withContext*: bool          # true = include (shared scope), false = render (isolated scope)
      includeArgCount*: uint8    # Number of keyword arguments
      includeArgNames*: seq[uint32]  # String IDs for keyword argument names
      includeVarExpr*: bool      # true = template name is a variable (on stack), false = string literal
      includeWithVar*: int32     # String ID for 'with' variable (-1 = none)
      includeAlias*: int32       # String ID for 'as' alias (-1 = none)
      includeForVar*: int32      # String ID for 'for' loop variable (-1 = none)
    of opBeginLoop:
      loopVarIndex*: uint16
      hasLimit*: bool
      hasOffset*: bool
      hasOffsetContinue*: bool  # offset: continue (resume from last position)
      isReversed*: bool         # reversed keyword
      loopNameId*: int32        # String ID for forloop.name (-1 = none)
    of opIterNext:
      endOffset*: int32       # Jump offset when iteration is exhausted
      elseOffset*: int32      # Jump offset when collection is empty (for else block)
    of opBreak, opContinue:
      levels*: uint8
    of opBatchOutput:
      batchCount*: uint8
      stringIds*: seq[uint32]
    of opBeginCapture:
      captureId*: uint32
    of opEndCapture:
      varId*: uint32
    of opCycle:
      cycleGroupId*: int32       # String ID for group name (-1 = unnamed, use cycleKey)
      cycleGroupIsVar*: bool     # true = group name is a variable (resolve at runtime)
      cycleArgCount*: uint8      # Number of cycle values (on stack)
      cycleKey*: uint32          # String ID for unnamed cycle key (built from source args)
    of opTablerowBegin:
      tablerowVarIndex*: uint16  # Local variable index for loop variable
      tablerowHasLimit*: bool
      tablerowHasOffset*: bool
      tablerowHasCols*: bool
    of opTablerowIter:
      tablerowEndOffset*: int32  # Jump offset when iteration is done
      tablerowBodyOffset*: int32 # Jump offset back to body start (negative)
    else:
      discard

  VMValueKind* = enum
    vmNull, vmBool, vmInt, vmFloat, vmString, vmArray, vmObject, vmLazy, vmIterator, vmEmpty

  # Values in the VM
  VMValue* = object
    case kind*: VMValueKind
    of vmNull:
      discard
    of vmEmpty:
      discard
    of vmBool:
      boolVal*: bool
    of vmInt:
      intVal*: int64
    of vmFloat:
      floatVal*: float64
    of vmString:
      stringVal*: string
    of vmArray:
      arrayVal*: seq[VMValue]
    of vmObject:
      objectVal*: OrderedTable[string, VMValue]
    of vmLazy:
      # For lazy evaluation of expensive operations
      lazyFn*: proc(): VMValue
    of vmIterator:
      # For efficient iteration without materializing
      iterFn*: proc(idx: int): VMValue
      iterLen*: int

  # Compiled Template - Cacheable unit
  CompiledTemplate* = object
    # Metadata for caching
    source_hash*: string          # Hash of source template
    compiled_at*: Time            # Compilation timestamp
    dependencies*: seq[string]   # Other templates this includes/extends
    
    # Bytecode
    instructions*: seq[Instruction]
    
    # Constant pools
    strings*: seq[string]        # String constants
    constants*: seq[VMValue]     # Other constants
    
    # Template structure
    blocks*: Table[string, int]  # Block name -> instruction offset
    macros*: Table[string, int]  # Macro name -> instruction offset
    
    # Debug info (optional)
    source_map*: seq[tuple[instruction: int, line: int, col: int]]

  VariableRequirements* = object
    required*: seq[string]      # Variables that MUST be provided
    optional*: seq[string]      # Variables that MAY be used
    locals*: seq[string]        # Variables created by template (assign, capture)
    
  # Compilation result
  CompileResult* = object
    bytecode*: seq[Instruction]
    strings*: seq[string]       # String constant pool
    constants*: seq[VMValue]    # Other constants
    variables*: VariableRequirements
    
  # Compiler state
  Compiler* = object
    # Input
    sections*: seq[Section]
    input*: string
    current_section*: int
    
    # Compilation options
    strict*: bool  # Strict mode for Ruby Liquid compatibility
    
    # Output being built
    instructions*: seq[Instruction]
    strings*: seq[string]
    string_map*: Table[string, uint32]
    constants*: seq[VMValue]
    
    # Variable tracking
    required_vars*: HashSet[string]
    optional_vars*: HashSet[string]
    local_vars*: HashSet[string]
    scope_depth*: int
    
    # Control flow tracking
    loop_depth*: int
    break_jumps*: seq[seq[int]]    # Stack of break positions per loop
    continue_jumps*: seq[seq[int]] # Stack of continue positions per loop

  