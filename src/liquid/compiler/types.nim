import std/[tables, sets]

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

    # Variable Operations
    opLoadVar            # Load variable: [stringId]
    opDynamicLoadVar     # Pop string from stack, use as variable name to load
    opStoreVar           # Store to variable: [stringId]

    # Property/Index Access
    opGetProp            # Get property: [stringId]
    opGetIndex           # Get array/object index (key on stack)

    # Output Operations
    opOutput             # Output top of stack
    opBatchOutput        # Output literal template text: [stringId]
    opBeginCapture       # Start capturing output
    opEndCapture         # End capture and store: [varId]

    # Control Flow
    opJump               # Unconditional jump: [offset]
    opJumpIfFalse        # Jump if false: [offset]
    opJumpIfTrue         # Jump if true: [offset]

    # Loops
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
    opAnd                # Logical AND (eager: both operands evaluated)
    opOr                 # Logical OR (eager: both operands evaluated)
    opNot                # Logical NOT

    # Filters
    opCallFilter         # Call filter: [filterId, argCount]

    # Tags (runtime dispatch to registered handlers)
    opCallTag            # Call custom tag: [tagId, argCount, tagData]

    # Template Operations
    opInclude            # Include template: [templateId, withContext]

    # Range
    opRange              # Create range: start..end on stack

    # Blank detection (whitespace-only block suppression)
    opBeginBlankCheck    # Mark start of potential blank block (save output position)
    opEndBlankCheck      # Check if block output is whitespace-only, if so truncate

  # Instruction with operands
  Instruction* = object
    case op*: OpCode
    of opPushInt:
      intVal*: int64
    of opPushFloat:
      floatVal*: float64
    of opPushString, opLoadVar, opStoreVar, opGetProp, opBatchOutput:
      stringId*: uint32
    of opJump, opJumpIfFalse, opJumpIfTrue:
      offset*: int32
    of opCallFilter:
      filterId*: uint32
      argCount*: uint8
    of opCallTag:
      tagId*: uint32          # String ID of tag name (for runtime dispatch)
      tagData*: seq[int32]    # Tag-specific data (jump offsets, flags, etc.)
    of opInclude:
      templateId*: uint32        # String ID of the partial name
      withContext*: bool          # true = include (shared scope), false = render (isolated scope)
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
    of opEndCapture:
      varId*: uint32
    else:
      discard

  VMValueKind* = enum
    vmNull, vmBool, vmInt, vmFloat, vmString, vmArray, vmObject, vmEmpty,
    vmNode

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
    of vmNode:
      ## A lazy container backed by an arena context store node: the raw
      ## NodeId of an object or array. Scalars are always wrapped eagerly,
      ## so a vmNode is never null, bool, number or string — truthiness,
      ## numeric coercion and ordering treat it exactly like the eager
      ## container kinds. The VM holds the arena; this module stays free
      ## of the dependency by carrying the id as a plain uint32.
      nodeVal*: uint32

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

  # Tag compiler registration
  TagCompileProc* = proc(c: var Compiler, tokens: openArray[Token]) {.nimcall.}
    ## A tag compilation function that emits bytecode for a tag.
    ## Block tags (if, for, etc.) handle their own section advancement.
    ## Inline tags (assign, increment, etc.) do NOT — the dispatcher advances.

  TagRegistration* = object
    name*: string           ## Tag name (e.g., "if", "for", "increment")
    compile*: TagCompileProc
    is_block*: bool         ## Block tags handle their own section advancement
    token_kind*: TokenKind  ## Lexer keyword token kind (tkIdentifier for non-keyword tags)

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

    # Tag registration
    tag_registry*: Table[string, TagRegistration]  ## Registered tag compilers
