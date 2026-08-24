# Handlebars compiler
# ===================
# Compiles the Handlebars token stream to Pitchfork bytecode on the same
# machinery as the other tines:
# - paths:        opResolveName (context-stack walk, ctxHops for ../)
#                 + opGetProp chains; @index/@key/@first/@last map onto the
#                 engine's forloop object; @root/this handled by the engine
# - helpers:      the shared filter registry (register_helper == register_filter);
#                 {{helper a b}} calls filter "helper" with value a, args [b]
# - truthiness:   registered normalizer filters (hb#section, hb#if, hb#with,
#                 hb#each) — language policy lives in the tine, per the
#                 "tines register truth evaluation" design
# - #each:        the standard opBeginLoop/opIterNext loop with
#                 objectAsValues (keys tracked for @key), else via elseOffset
# - partials:     opInclude with shared scope, optional context expression
#                 (a pushed context frame) and hash arguments (keyword args)
#
# Not supported yet (raise a compile error where detectable): custom block
# helpers, hash arguments on non-partial helpers, dynamic partial names,
# block parameters (as |x|), lambdas.

import std/[tables, sets, strutils]

import ../../bytecode
import ../../values
import ../../emitter
import lexer

# ── Registered truthiness / normalization policies ───────────────────

const hb_section_filter* = "hb#section"  ## {{#value}}: falsy = null/false/""/[]
const hb_if_filter* = "hb#if"            ## #if/#unless: JS-falsy or empty list
const hb_with_filter* = "hb#with"        ## #with: isEmpty; lists kept whole
const hb_each_filter* = "hb#each"        ## #each: lists/objects iterate

proc hb_section_normalizer(value: VMValue, args: varargs[VMValue]): VMValue =
  ## Handlebars blockHelperMissing semantics: falsy (null/false/""/empty
  ## list) renders nothing; lists iterate; anything else (0 included)
  ## renders once with the value as context.
  var items: seq[VMValue] = @[]
  case value.kind
  of vmNull, vmEmpty: discard
  of vmBool:
    if value.boolVal: items.add(value)
  of vmString:
    if value.stringVal.len > 0: items.add(value)
  of vmArray:
    items = value.arrayVal
  else:
    items.add(value)
  VMValue(kind: vmArray, arrayVal: items)

proc hb_if_normalizer(value: VMValue, args: varargs[VMValue]): VMValue =
  ## #if truthiness: JS-falsy (false/null/""/0/0.0) or an empty list is falsy.
  var items: seq[VMValue] = @[]
  case value.kind
  of vmNull, vmEmpty: discard
  of vmBool:
    if value.boolVal: items.add(value)
  of vmString:
    if value.stringVal.len > 0: items.add(value)
  of vmInt:
    if value.intVal != 0: items.add(value)
  of vmFloat:
    if value.floatVal != 0.0: items.add(value)
  of vmArray:
    if value.arrayVal.len > 0: items.add(value)
  else:
    items.add(value)
  VMValue(kind: vmArray, arrayVal: items)

proc hb_with_normalizer(value: VMValue, args: varargs[VMValue]): VMValue =
  ## #with: isEmpty (null/false/""/empty list) is falsy; a non-empty list
  ## is kept whole (it becomes the context, not an iteration).
  var items: seq[VMValue] = @[]
  case value.kind
  of vmNull, vmEmpty: discard
  of vmBool:
    if value.boolVal: items.add(value)
  of vmString:
    if value.stringVal.len > 0: items.add(value)
  of vmArray:
    if value.arrayVal.len > 0: items.add(value)
  else:
    items.add(value)
  VMValue(kind: vmArray, arrayVal: items)

proc hb_each_normalizer(value: VMValue, args: varargs[VMValue]): VMValue =
  ## #each: lists iterate as-is; objects pass through so opBeginLoop can
  ## iterate them as values with keys tracked; anything else iterates nothing.
  case value.kind
  of vmArray, vmObject:
    value
  else:
    VMValue(kind: vmArray, arrayVal: @[])

register_filter(hb_section_filter, hb_section_normalizer)
register_filter(hb_if_filter, hb_if_normalizer)
register_filter(hb_with_filter, hb_with_normalizer)
register_filter(hb_each_filter, hb_each_normalizer)

# ── Expression AST + parser ───────────────────────────────────────────

type
  ExprKind = enum ekPath, ekString, ekInt, ekFloat, ekBool, ekNull, ekCall
  Expr = ref object
    case kind: ExprKind
    of ekPath:
      segments: seq[string]
      hops: int
    of ekString:
      sval: string
    of ekInt:
      ival: int64
    of ekFloat:
      fval: float64
    of ekBool:
      bval: bool
    of ekNull:
      discard
    of ekCall:
      callee: string
      call_args: seq[Expr]

  HashArg = tuple[name: string, value: Expr]

  ETokKind = enum etSym, etStr, etLParen, etRParen, etEq
  ETok = object
    kind: ETokKind
    s: string

proc expr_error(msg, content: string): ref ValueError =
  newException(ValueError, "Handlebars expression error in {{" & content & "}}: " & msg)

proc etokenize(content: string): seq[ETok] =
  var i = 0
  while i < content.len:
    let ch = content[i]
    case ch
    of ' ', '\t', '\r', '\n':
      inc i
    of '(':
      result.add(ETok(kind: etLParen)); inc i
    of ')':
      result.add(ETok(kind: etRParen)); inc i
    of '=':
      result.add(ETok(kind: etEq)); inc i
    of '"', '\'':
      var s = ""
      inc i
      while i < content.len and content[i] != ch:
        if content[i] == '\\' and i + 1 < content.len:
          s.add(content[i + 1]); i += 2
        else:
          s.add(content[i]); inc i
      if i >= content.len:
        raise expr_error("unterminated string literal", content)
      inc i
      result.add(ETok(kind: etStr, s: s))
    else:
      var s = ""
      while i < content.len:
        let c = content[i]
        if c == '[':
          # Segment literal: consumed atomically, brackets kept for the
          # path splitter
          s.add(c); inc i
          while i < content.len and content[i] != ']':
            s.add(content[i]); inc i
          if i < content.len:
            s.add(']'); inc i
        elif c in {' ', '\t', '\r', '\n', '(', ')', '='}:
          break
        else:
          s.add(c); inc i
      result.add(ETok(kind: etSym, s: s))

proc parse_path(sym: string): Expr =
  var hops = 0
  var rest = sym
  while rest.startsWith("../"):
    inc hops
    rest = rest[3..^1]
  if rest == "..":
    inc hops
    rest = ""
  if rest.startsWith("./"):
    rest = rest[2..^1]

  var segs: seq[string] = @[]
  var cur = ""
  var i = 0
  while i < rest.len:
    let c = rest[i]
    if c == '[':
      inc i
      while i < rest.len and rest[i] != ']':
        cur.add(rest[i]); inc i
      if i < rest.len: inc i
    elif c in {'.', '/'}:
      if cur.len > 0:
        segs.add(cur)
        cur = ""
      inc i
    else:
      cur.add(c); inc i
  if cur.len > 0:
    segs.add(cur)

  if segs.len > 0 and segs[0] == "this":
    segs = segs[1..^1]
  if segs.len == 0:
    return Expr(kind: ekPath, segments: @["."], hops: hops)

  # A leading numeric segment indexes the current context: {{[0]}} == this.[0]
  if segs[0].len > 0 and segs[0].allCharsInSet({'0'..'9'}):
    segs = @["."] & segs

  # @data variables ride on the engine's forloop object
  case segs[0]
  of "@index": segs = @["forloop", "index0"] & segs[1..^1]
  of "@key":   segs = @["forloop", "key"] & segs[1..^1]
  of "@first": segs = @["forloop", "first"] & segs[1..^1]
  of "@last":  segs = @["forloop", "last"] & segs[1..^1]
  else: discard  # includes @root, resolved by the engine
  Expr(kind: ekPath, segments: segs, hops: hops)

proc is_number(s: string): bool =
  if s.len == 0: return false
  var i = 0
  if s[0] == '-':
    if s.len == 1: return false
    i = 1
  var dots = 0
  for j in i ..< s.len:
    if s[j] == '.':
      inc dots
      if dots > 1: return false
    elif s[j] notin {'0'..'9'}:
      return false
  true

proc parse_atom(sym: string): Expr =
  case sym
  of "true": Expr(kind: ekBool, bval: true)
  of "false": Expr(kind: ekBool, bval: false)
  of "null", "undefined": Expr(kind: ekNull)
  else:
    if is_number(sym):
      if '.' in sym:
        Expr(kind: ekFloat, fval: parseFloat(sym))
      else:
        Expr(kind: ekInt, ival: parseBiggestInt(sym))
    else:
      parse_path(sym)

proc parse_exprs(toks: seq[ETok], i: var int, content: string,
                 stop_at_rparen: bool): (seq[Expr], seq[HashArg])

proc parse_single(toks: seq[ETok], i: var int, content: string): Expr =
  ## One expression: literal, path, or (subexpression)
  if i >= toks.len:
    raise expr_error("expected an expression", content)
  case toks[i].kind
  of etStr:
    result = Expr(kind: ekString, sval: toks[i].s)
    inc i
  of etSym:
    result = parse_atom(toks[i].s)
    inc i
  of etLParen:
    inc i
    if i >= toks.len or toks[i].kind != etSym:
      raise expr_error("subexpression must start with a helper name", content)
    let callee = toks[i].s
    inc i
    let (args, hash) = parse_exprs(toks, i, content, stop_at_rparen = true)
    if hash.len > 0:
      raise expr_error("hash arguments in subexpressions are not supported yet", content)
    if i >= toks.len or toks[i].kind != etRParen:
      raise expr_error("unclosed subexpression", content)
    inc i
    result = Expr(kind: ekCall, callee: callee, call_args: args)
  else:
    raise expr_error("unexpected token", content)

proc parse_exprs(toks: seq[ETok], i: var int, content: string,
                 stop_at_rparen: bool): (seq[Expr], seq[HashArg]) =
  var exprs: seq[Expr] = @[]
  var hash: seq[HashArg] = @[]
  while i < toks.len:
    if toks[i].kind == etRParen:
      if stop_at_rparen:
        break
      raise expr_error("unexpected ')'", content)
    # key=value hash argument?
    if toks[i].kind == etSym and i + 1 < toks.len and toks[i + 1].kind == etEq:
      let name = toks[i].s
      i += 2
      hash.add((name, parse_single(toks, i, content)))
      continue
    if hash.len > 0:
      raise expr_error("positional argument after hash argument", content)
    exprs.add(parse_single(toks, i, content))
  (exprs, hash)

proc parse_content(content: string): (seq[Expr], seq[HashArg]) =
  let toks = etokenize(content)
  var i = 0
  result = parse_exprs(toks, i, content, stop_at_rparen = false)

# ── Compiler ──────────────────────────────────────────────────────────

type
  Compiler* = object of Emitter
    tokens*: seq[HToken]
    pos*: int
    ctx_depth*: int

proc compile_error(msg: string): ref ValueError =
  newException(ValueError, "Handlebars compile error: " & msg)

proc emit_call(c: var Compiler, callee: string, args: seq[Expr])

proc emit_expr(c: var Compiler, e: Expr) =
  case e.kind
  of ekPath:
    c.emit(Instruction(op: opResolveName,
      nameId: c.intern_string(e.segments[0]), ctxHops: e.hops.uint8))
    if e.hops == 0 and c.scope_depth == 0 and
       e.segments[0] notin [".", "@root", "forloop"]:
      c.optional_vars.incl(e.segments[0])
    for i in 1 ..< e.segments.len:
      c.emit(Instruction(op: opGetProp, stringId: c.intern_string(e.segments[i])))
  of ekString:
    c.emit(Instruction(op: opPushString, stringId: c.intern_string(e.sval)))
  of ekInt:
    c.emit(Instruction(op: opPushInt, intVal: e.ival))
  of ekFloat:
    c.emit(Instruction(op: opPushFloat, floatVal: e.fval))
  of ekBool:
    c.emit(Instruction(op: if e.bval: opPushTrue else: opPushFalse))
  of ekNull:
    c.emit(Instruction(op: opPushNull))
  of ekCall:
    c.emit_call(e.callee, e.call_args)

proc emit_call(c: var Compiler, callee: string, args: seq[Expr]) =
  ## Helpers ride the shared filter registry: first argument is the
  ## filtered value, the rest are filter arguments.
  if args.len == 0:
    c.emit(Instruction(op: opPushNull))
    c.emit(Instruction(op: opCallFilter,
      filterId: c.intern_string(callee), argCount: 0))
  else:
    c.emit_expr(args[0])
    for i in 1 ..< args.len:
      c.emit_expr(args[i])
    c.emit(Instruction(op: opCallFilter,
      filterId: c.intern_string(callee), argCount: uint8(args.len - 1)))

proc emit_output_tag(c: var Compiler, content: string, escaped: bool) =
  let (exprs, hash) = parse_content(content)
  if hash.len > 0:
    raise compile_error("hash arguments on helpers are not supported yet: {{" & content & "}}")
  if exprs.len == 0:
    raise compile_error("empty expression: {{" & content & "}}")
  if exprs.len == 1:
    c.emit_expr(exprs[0])
  else:
    # {{helper a b ...}}
    if exprs[0].kind != ekPath or exprs[0].segments.len != 1 or exprs[0].hops != 0:
      raise compile_error("helper name expected: {{" & content & "}}")
    c.emit_call(exprs[0].segments[0], exprs[1..^1])
  c.emit(Instruction(op: if escaped: opOutputEscaped else: opOutput))

proc open_key(content: string): string =
  ## The token a close tag must match: the first word of the open tag.
  let toks = etokenize(content)
  if toks.len == 0 or toks[0].kind != etSym:
    raise compile_error("malformed block tag: {{#" & content & "}}")
  toks[0].s

# Compiles tokens until {{else}} (returns true) or the matching
# {{/close}} (returns false).
proc compile_until(c: var Compiler, close: string): bool

proc emit_normalized(c: var Compiler, value: Expr, normalizer: string) =
  c.emit_expr(value)
  c.emit(Instruction(op: opCallFilter,
    filterId: c.intern_string(normalizer), argCount: 0))

proc emit_empty_check(c: var Compiler) =
  ## Consumes a normalized list, pushes whether it is empty
  c.emit(Instruction(op: opPushEmpty))
  c.emit(Instruction(op: opEqual))

proc compile_branch_block(c: var Compiler, value: Expr, normalizer: string,
                          close: string, inverted: bool) =
  ## #if / #unless / plain inverse blocks: no context push, two branches.
  c.emit_normalized(value, normalizer)
  c.emit_empty_check()
  # empty on top: for a normal block jump to else when empty; for an
  # inverted block jump to else when NOT empty
  let to_else = c.emit_jump(if inverted: opJumpIfFalse else: opJumpIfTrue)
  let has_else = c.compile_until(close)
  if has_else:
    let to_end = c.emit_jump(opJump)
    c.patch_jump(to_else)
    discard c.compile_until(close)
    c.patch_jump(to_end)
  else:
    c.patch_jump(to_else)

proc compile_with_block(c: var Compiler, value: Expr, close: string) =
  c.emit_expr(value)
  c.emit(Instruction(op: opDup))
  c.emit(Instruction(op: opCallFilter,
    filterId: c.intern_string(hb_with_filter), argCount: 0))
  c.emit_empty_check()
  let to_else = c.emit_jump(opJumpIfTrue)
  # Truthy: the duplicated value becomes the context
  c.emit(Instruction(op: opPushCtx))
  inc c.scope_depth
  let has_else = c.compile_until(close)
  dec c.scope_depth
  c.emit(Instruction(op: opPopCtx))
  let to_end = c.emit_jump(opJump)
  c.patch_jump(to_else)
  # Falsy: discard the duplicated value
  c.emit(Instruction(op: opPop))
  if has_else:
    discard c.compile_until(close)
  c.patch_jump(to_end)

proc compile_loop_block(c: var Compiler, value: Expr, normalizer: string,
                        close: string, object_as_values: bool) =
  ## #each and plain {{#value}} sections: the standard engine loop with
  ## each item bound as the current context; {{else}} via elseOffset.
  c.emit_normalized(value, normalizer)
  c.emit(Instruction(op: opPushNull))
  c.emit(Instruction(op: opPushCtx))
  let loop_var = "__ctx_" & $c.ctx_depth
  inc c.ctx_depth
  inc c.scope_depth
  c.emit(Instruction(op: opBeginLoop, buildsForloop: true,
    loopVarIndex: c.intern_string(loop_var).uint16,
    hasLimit: false, hasOffset: false, hasOffsetContinue: false,
    isReversed: false, loopNameId: -1, objectAsValues: object_as_values))
  let iter_pos = c.instructions.len
  c.emit(Instruction(op: opIterNext, endOffset: 0, elseOffset: 0))
  c.emit(Instruction(op: opSetCtx))
  let has_else = c.compile_until(close)
  c.emit(Instruction(op: opJump,
    offset: int32(iter_pos - c.instructions.len - 1)))
  var else_offset = 0'i32
  if has_else:
    else_offset = int32(c.instructions.len - iter_pos - 1)
    discard c.compile_until(close)
  let end_offset = int32(c.instructions.len - iter_pos - 1)
  c.instructions[iter_pos] = Instruction(op: opIterNext,
    endOffset: end_offset, elseOffset: else_offset)
  c.emit(Instruction(op: opPopCtx))
  dec c.scope_depth
  dec c.ctx_depth

proc compile_block_open(c: var Compiler, content: string) =
  let key = open_key(content)
  let (exprs, hash) = parse_content(content)
  if hash.len > 0:
    raise compile_error("hash arguments on block helpers are not supported yet: {{#" & content & "}}")
  case key
  of "if":
    if exprs.len != 2:
      raise compile_error("#if takes exactly one argument: {{#" & content & "}}")
    c.compile_branch_block(exprs[1], hb_if_filter, key, inverted = false)
  of "unless":
    if exprs.len != 2:
      raise compile_error("#unless takes exactly one argument: {{#" & content & "}}")
    c.compile_branch_block(exprs[1], hb_if_filter, key, inverted = true)
  of "with":
    if exprs.len != 2:
      raise compile_error("#with takes exactly one argument: {{#" & content & "}}")
    c.compile_with_block(exprs[1], key)
  of "each":
    if exprs.len != 2:
      raise compile_error("#each takes exactly one argument: {{#" & content & "}}")
    c.compile_loop_block(exprs[1], hb_each_filter, key, object_as_values = true)
  else:
    if exprs.len != 1:
      raise compile_error("custom block helpers are not supported yet: {{#" & content & "}}")
    c.compile_loop_block(exprs[0], hb_section_filter, key, object_as_values = false)

proc compile_inverse_open(c: var Compiler, content: string) =
  let key = open_key(content)
  let (exprs, hash) = parse_content(content)
  if hash.len > 0 or exprs.len != 1:
    raise compile_error("malformed inverse section: {{^" & content & "}}")
  c.compile_branch_block(exprs[0], hb_section_filter, key, inverted = true)

proc compile_partial(c: var Compiler, tok: HToken) =
  let toks = etokenize(tok.content)
  var i = 0
  if i >= toks.len:
    raise compile_error("partial name expected: {{> " & tok.content & "}}")
  var name: string
  case toks[i].kind
  of etSym: name = toks[i].s
  of etStr: name = toks[i].s
  else:
    raise compile_error("dynamic partial names are not supported yet: {{> " & tok.content & "}}")
  inc i
  # Optional context expression, then hash arguments
  var ctx_expr: Expr = nil
  var hash: seq[HashArg] = @[]
  if i < toks.len and not (toks[i].kind == etSym and
                           i + 1 < toks.len and toks[i + 1].kind == etEq):
    ctx_expr = parse_single(toks, i, tok.content)
  while i < toks.len:
    if toks[i].kind == etSym and i + 1 < toks.len and toks[i + 1].kind == etEq:
      let hname = toks[i].s
      i += 2
      hash.add((hname, parse_single(toks, i, tok.content)))
    else:
      raise compile_error("unexpected token in partial: {{> " & tok.content & "}}")

  if ctx_expr != nil:
    c.emit_expr(ctx_expr)
    c.emit(Instruction(op: opPushCtx))
  var arg_names: seq[uint32] = @[]
  for (hname, hval) in hash:
    c.emit_expr(hval)
    arg_names.add(c.intern_string(hname))
  c.emit(Instruction(op: opInclude,
    templateId: c.intern_string(name),
    withContext: true,
    includeArgNames: arg_names,
    includeVarExpr: false,
    includeWithVar: -1,
    includeAlias: -1,
    includeForVar: -1,
    includeHasIndent: tok.indent.len > 0,
    includeIndentId: c.intern_string(tok.indent)))
  if ctx_expr != nil:
    c.emit(Instruction(op: opPopCtx))

proc compile_until(c: var Compiler, close: string): bool =
  while c.pos < c.tokens.len:
    let tok = c.tokens[c.pos]
    inc c.pos
    case tok.kind
    of hText:
      c.emit(Instruction(op: opBatchOutput, stringId: c.intern_string(tok.text)))
    of hExpr:
      c.emit_output_tag(tok.content, escaped = true)
    of hExprRaw:
      c.emit_output_tag(tok.content, escaped = false)
    of hBlockOpen:
      c.compile_block_open(tok.content)
    of hInverseOpen:
      c.compile_inverse_open(tok.content)
    of hElse:
      if close.len == 0:
        raise compile_error("{{else}} outside of a block")
      return true
    of hBlockClose:
      if close.len == 0 or tok.content != close:
        raise compile_error("unexpected {{/" & tok.content & "}}")
      return false
    of hPartial:
      c.compile_partial(tok)
    of hComment:
      discard
  if close.len > 0:
    raise compile_error("unclosed block: {{#" & close & "}}")
  false

proc compile*(tokens: seq[HToken]): CompileResult =
  var c = Compiler(tokens: tokens, pos: 0, ctx_depth: 0)
  c.init_emitter(tokens.len * 4)
  discard c.compile_until("")
  result = c.to_compile_result()
