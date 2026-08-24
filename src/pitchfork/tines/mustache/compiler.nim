# Mustache compiler
# =================
# Compiles the Mustache token stream to Pitchfork bytecode. Reuses the
# engine's existing machinery throughout:
# - name lookup:      opResolveName (context-stack walk) + opGetProp chains
# - sections:         opNormalizeSection + the standard opBeginLoop/opIterNext
#                     loop, with opSetCtx binding each item as current context
# - inverted:         opNormalizeSection + comparison against `empty`
# - interpolation:    opOutputEscaped ({{ }}) / opOutput ({{{ }}})
# - partials:         opInclude with shared scope and optional indent

import std/[tables, sets, strutils]

import ../../bytecode
import ../../emitter
import lexer

type
  Compiler* = object of Emitter
    tokens*: seq[MToken]
    pos*: int
    ctx_depth*: int   # For unique per-nesting iterator variable names

proc emit_resolve(c: var Compiler, name: seq[string]) =
  ## Emit name resolution: first segment through the context stack,
  ## remaining segments as property accesses.
  c.emit(Instruction(op: opResolveName, stringId: c.intern_string(name[0])))
  if name[0] != "." and c.scope_depth == 0:
    c.optional_vars.incl(name[0])
  for i in 1 ..< name.len:
    c.emit(Instruction(op: opGetProp, stringId: c.intern_string(name[i])))

proc compile_tokens(c: var Compiler, until_close: seq[string] = @[]) =
  ## Compile tokens until a matching section close (or end of input when
  ## until_close is empty).
  while c.pos < c.tokens.len:
    let tok = c.tokens[c.pos]
    inc c.pos
    case tok.kind
    of mText:
      c.emit(Instruction(op: opBatchOutput, batchCount: 1,
                         stringIds: @[c.intern_string(tok.text)]))

    of mVariable:
      c.emit_resolve(tok.name)
      c.emit(Instruction(op: opOutputEscaped))

    of mUnescaped:
      c.emit_resolve(tok.name)
      c.emit(Instruction(op: opOutput))

    of mSectionOpen:
      # value -> item list -> loop, binding each item as current context
      c.emit_resolve(tok.name)
      c.emit(Instruction(op: opNormalizeSection))
      # Reserve a context frame for the loop body (replaced per iteration)
      c.emit(Instruction(op: opPushNull))
      c.emit(Instruction(op: opPushCtx))
      let loop_var = "__ctx_" & $c.ctx_depth
      inc c.ctx_depth
      inc c.scope_depth
      c.emit(Instruction(op: opBeginLoop,
        loopVarIndex: c.intern_string(loop_var).uint16,
        hasLimit: false, hasOffset: false, hasOffsetContinue: false,
        isReversed: false, loopNameId: -1))
      let loop_start = c.instructions.len
      let iter_pos = c.instructions.len
      c.emit(Instruction(op: opIterNext, endOffset: 0, elseOffset: 0))
      c.emit(Instruction(op: opSetCtx))
      c.compile_tokens(tok.name)
      # Jump back to opIterNext
      c.emit(Instruction(op: opJump,
        offset: int32(loop_start - c.instructions.len - 1)))
      c.instructions[iter_pos] = Instruction(op: opIterNext,
        endOffset: int32(c.instructions.len - iter_pos - 1), elseOffset: 0)
      c.emit(Instruction(op: opPopCtx))
      dec c.scope_depth
      dec c.ctx_depth

    of mInvertedOpen:
      # Render the body only when the normalized section list is empty
      c.emit_resolve(tok.name)
      c.emit(Instruction(op: opNormalizeSection))
      c.emit(Instruction(op: opPushEmpty))
      c.emit(Instruction(op: opEqual))
      let jmp = c.emit_jump(opJumpIfFalse)
      c.compile_tokens(tok.name)
      c.patch_jump(jmp)

    of mSectionClose:
      if until_close.len == 0 or tok.name != until_close:
        raise newException(ValueError,
          "Unexpected section close: {{/" & tok.name.join(".") & "}}")
      return

    of mPartial:
      c.emit(Instruction(op: opInclude,
        templateId: c.intern_string(tok.partial_name),
        withContext: true,
        includeArgCount: 0,
        includeArgNames: @[],
        includeVarExpr: false,
        includeWithVar: -1,
        includeAlias: -1,
        includeForVar: -1,
        includeHasIndent: tok.indent.len > 0,
        includeIndentId: c.intern_string(tok.indent)))

  if until_close.len > 0:
    raise newException(ValueError,
      "Unclosed section: {{#" & until_close.join(".") & "}}")

proc compile*(tokens: seq[MToken]): CompileResult =
  var c = Compiler(tokens: tokens, pos: 0, ctx_depth: 0)
  c.init_emitter(tokens.len * 4)
  c.compile_tokens()
  result = c.to_compile_result()
