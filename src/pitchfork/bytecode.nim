# Pitchfork bytecode: the language-agnostic instruction set shared by all
# template frontends (tines) and executed by the common VM.

import std/tables

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
    opResolveName        # Resolve name: context-stack walk, then the flat
                         # scope chain (keyword_args/locals/variables/counters).
                         # With an empty context stack this is a plain
                         # variable load: [stringId]
    opDynamicLoadVar     # Pop string from stack, use as variable name to load
    opStoreVar           # Store to variable: [stringId]

    # Context stack (scoped name resolution for Mustache-family languages)
    # Section-value normalization (which values are falsy, what iterates)
    # is language policy, not engine mechanism: each tine registers it as
    # a namespaced filter (e.g. "mustache#section") and compiles sections
    # to a plain opCallFilter on it.
    opPushCtx            # Pop value, push it onto the context stack
    opPopCtx             # Pop the context stack
    opSetCtx             # Pop value, replace top of the context stack

    # Property/Index Access
    opGetProp            # Get property: [stringId]
    opGetIndex           # Get array/object index (key on stack)

    # Output Operations
    opOutput             # Output top of stack (escaped iff vm.escape_html)
    opOutputEscaped      # Output top of stack, always HTML-escaped
    opBatchOutput        # Output multiple constants: [count, id1, id2, ...]
    opBeginCapture       # Start capturing output: [captureId]
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
    opAnd                # Logical AND (short-circuit)
    opOr                 # Logical OR (short-circuit)
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
    of opPushString, opStoreVar, opGetProp:
      stringId*: uint32
    of opResolveName:
      nameId*: uint32
      ctxHops*: uint8         # Skip N context frames from the top (Handlebars ../)
    of opJump, opJumpIfFalse, opJumpIfTrue:
      offset*: int32
    of opCallFilter:
      filterId*: uint32
      argCount*: uint8
    of opCallTag:
      tagId*: uint32          # String ID of tag name (for runtime dispatch)
      tagArgCount*: uint8     # Number of arguments on stack
      tagData*: seq[int32]    # Tag-specific data (jump offsets, flags, etc.)
    of opInclude:
      templateId*: uint32        # String ID of the partial name
      withContext*: bool          # true = include (shared scope), false = render (isolated scope)
      includeArgCount*: uint8    # Number of keyword arguments
      includeArgNames*: seq[uint32]  # String IDs for keyword argument names
      includeVarExpr*: bool      # true = template name is a variable (on stack), false = string literal
      includeWithVar*: int32     # String ID for 'with' variable (-1 = none)
      includeAlias*: int32       # String ID for 'as' alias (-1 = none)
      includeForVar*: int32      # String ID for 'for' loop variable (-1 = none)
      includeHasIndent*: bool    # Mustache: indent each output line (standalone partials)
      includeIndentId*: uint32   # String ID of the indent whitespace
    of opBeginLoop:
      loopVarIndex*: uint16
      hasLimit*: bool
      hasOffset*: bool
      hasOffsetContinue*: bool  # offset: continue (resume from last position)
      isReversed*: bool         # reversed keyword
      loopNameId*: int32        # String ID for forloop.name (-1 = none)
      objectAsValues*: bool     # Iterate objects as values with keys tracked
                                # (Handlebars #each); default: [key, value] pairs
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
    else:
      discard

  VMValueKind* = enum
    vmNull, vmBool, vmInt, vmFloat, vmString, vmArray, vmObject, vmEmpty

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

  # A complete source -> bytecode pipeline for one template language.
  # The VM uses this to compile partials in the same language as the
  # template that included them.
  TemplateCompiler* = proc(source: string): CompileResult {.nimcall.}
