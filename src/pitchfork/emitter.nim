# Pitchfork emitter: language-agnostic bytecode emission state and helpers.
# A template language frontend (a "tine") embeds this via object inheritance:
#
#   type Compiler* = object of Emitter
#     ...frontend-specific parse state...
#
# and drives emit/intern_string/emit_jump/patch_jump while walking its own
# source representation. When done, to_compile_result() packages the output.

import std/[tables, sets, sequtils]

import bytecode

type
  Emitter* = object of RootObj
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

proc init_emitter*(e: var Emitter, instruction_cap: int = 64) =
  ## Initialize emitter state on a freshly constructed (sub)object.
  e.instructions = newSeqOfCap[Instruction](instruction_cap)
  e.strings = @[]
  e.string_map = initTable[string, uint32]()
  e.constants = @[]
  e.required_vars = initHashSet[string]()
  e.optional_vars = initHashSet[string]()
  e.local_vars = initHashSet[string]()
  e.scope_depth = 0
  e.loop_depth = 0

proc intern_string*(e: var Emitter, s: string): uint32 =
  if s in e.string_map:
    return e.string_map[s]
  result = e.strings.len.uint32
  e.strings.add(s)
  e.string_map[s] = result

proc emit*(e: var Emitter, inst: Instruction) =
  e.instructions.add(inst)

proc emit_jump*(e: var Emitter, op: OpCode): int =
  ## Emit jump with placeholder offset, return position for patching
  let inst = case op
    of opJump:
      Instruction(op: opJump, offset: 0'i32)
    of opJumpIfFalse:
      Instruction(op: opJumpIfFalse, offset: 0'i32)
    of opJumpIfTrue:
      Instruction(op: opJumpIfTrue, offset: 0'i32)
    else:
      raise newException(ValueError, "Invalid jump opcode: " & $op)

  e.emit(inst)
  result = e.instructions.len - 1

proc patch_jump*(e: var Emitter, pos: int) =
  ## Patch jump at pos to jump to current position
  let offset = e.instructions.len - pos - 1

  case e.instructions[pos].op
  of opJump:
    e.instructions[pos] = Instruction(op: opJump, offset: offset.int32)
  of opJumpIfFalse:
    e.instructions[pos] = Instruction(op: opJumpIfFalse, offset: offset.int32)
  of opJumpIfTrue:
    e.instructions[pos] = Instruction(op: opJumpIfTrue, offset: offset.int32)
  of opIterNext:
    e.instructions[pos] = Instruction(op: opIterNext, endOffset: offset.int32)
  else:
    raise newException(ValueError, "Attempting to patch non-jump instruction")

proc to_compile_result*(e: Emitter): CompileResult =
  result.bytecode = e.instructions
  result.strings = e.strings
  result.constants = e.constants
  result.variables.required = toSeq(e.required_vars)
  result.variables.optional = toSeq(e.optional_vars)
  result.variables.locals = toSeq(e.local_vars)
