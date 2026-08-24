# Handlebars lexer
# ================
# Tokenizes Handlebars source. Tag *content* (paths, helper calls,
# literals, hash args) is kept as a raw string here and parsed by the
# compiler's expression parser. This pass handles:
# - {{expr}} / {{{expr}}} / {{&expr}}
# - {{#block ...}} / {{^inverse ...}} / {{else}} ({{^}}) / {{/close}}
# - {{> partial ...}}
# - {{! comment }} and {{!-- comment with {{mustaches}} --}}
# - {{{{raw}}}} ... {{{{/raw}}}} raw blocks
# - {{~tilde~}} whitespace control
# - Mustache-style standalone-line stripping for block/comment/partial
#   tags, with indentation capture for standalone partials.

import std/strutils

type
  HTokenKind* = enum
    hText         # Literal template text
    hExpr         # {{expr}} — HTML-escaped output
    hExprRaw      # {{{expr}}} / {{&expr}} — raw output
    hBlockOpen    # {{#...}}
    hInverseOpen  # {{^...}}
    hElse         # {{else}} / {{^}}
    hBlockClose   # {{/...}}
    hPartial      # {{> ...}}
    hComment      # zero-width; kept until the whitespace passes are done

  HToken* = object
    kind*: HTokenKind
    text*: string      # hText payload
    content*: string   # raw tag content (sigil stripped) for expr/block/partial
    indent*: string    # hPartial: standalone indentation
    trim_left*: bool   # {{~ — strip whitespace before this tag
    trim_right*: bool  # ~}} — strip whitespace after this tag

proc lex_error(msg: string, pos: int): ref ValueError =
  newException(ValueError, "Handlebars lex error at offset " & $pos & ": " & msg)

proc tokenize(input: string): seq[HToken] =
  var pos = 0
  var text = ""

  template flush_text() =
    if text.len > 0:
      result.add(HToken(kind: hText, text: text))
      text = ""

  while pos < input.len:
    if input.continuesWith("{{", pos):
      flush_text()

      if input.continuesWith("{{{{", pos):
        # Raw block: {{{{name}}}} ... {{{{/name}}}}
        let stop = input.find("}}}}", pos + 4)
        if stop < 0:
          raise lex_error("unclosed raw block tag", pos)
        let name = input[pos + 4 ..< stop].strip()
        let close_seq = "{{{{/" & name & "}}}}"
        let close_at = input.find(close_seq, stop + 4)
        if close_at < 0:
          raise lex_error("unclosed raw block: " & name, pos)
        result.add(HToken(kind: hText, text: input[stop + 4 ..< close_at]))
        pos = close_at + close_seq.len
        continue

      if input.continuesWith("{{{", pos):
        let stop = input.find("}}}", pos + 3)
        if stop < 0:
          raise lex_error("unclosed '{{{'", pos)
        result.add(HToken(kind: hExprRaw, content: input[pos + 3 ..< stop].strip()))
        pos = stop + 3
        continue

      var i = pos + 2
      var tok = HToken(kind: hExpr)
      if i < input.len and input[i] == '~':
        tok.trim_left = true
        inc i

      if input.continuesWith("!--", i):
        let stop = input.find("--}}", i + 3)
        if stop < 0:
          raise lex_error("unclosed block comment", pos)
        tok.kind = hComment
        pos = stop + 4
        # A block comment may end with --~}}? Handlebars allows {{!-- --~}};
        # check for the tilde variant
        if stop >= 1 and input.continuesWith("--~}}", stop):
          discard  # not reachable: we searched for "--}}" first
        result.add(tok)
        continue

      let stop = input.find("}}", i)
      if stop < 0:
        raise lex_error("unclosed tag", pos)
      var inner = input[i ..< stop]
      pos = stop + 2
      if inner.endsWith("~"):
        tok.trim_right = true
        inner = inner[0 ..< ^1]
      inner = inner.strip()

      if inner.len == 0:
        raise lex_error("empty tag", pos)

      case inner[0]
      of '!':
        tok.kind = hComment
      of '#':
        tok.kind = hBlockOpen
        tok.content = inner[1..^1].strip()
      of '^':
        let rest = inner[1..^1].strip()
        if rest.len == 0:
          tok.kind = hElse
        else:
          tok.kind = hInverseOpen
          tok.content = rest
      of '/':
        tok.kind = hBlockClose
        tok.content = inner[1..^1].strip()
      of '>':
        tok.kind = hPartial
        tok.content = inner[1..^1].strip()
      of '&':
        tok.kind = hExprRaw
        tok.content = inner[1..^1].strip()
      else:
        if inner == "else":
          tok.kind = hElse
        else:
          tok.kind = hExpr
          tok.content = inner
      result.add(tok)
    else:
      text.add(input[pos])
      if input[pos] == '\n':
        flush_text()
      inc pos
  flush_text()

proc is_whitespace_text(t: HToken): bool =
  t.kind == hText and t.text.allCharsInSet({' ', '\t', '\r', '\n'})

proc strip_standalone(tokens: var seq[HToken]) =
  ## Mustache-style standalone-line stripping: a line whose only
  ## non-whitespace content is exactly one block/else/close/partial tag
  ## (or only comments) loses its surrounding whitespace and line ending.
  ## Standalone partials capture their indentation.
  var i = 0
  while i < tokens.len:
    var line_end = i
    while line_end < tokens.len:
      if tokens[line_end].kind == hText and tokens[line_end].text.endsWith("\n"):
        break
      inc line_end
    let last = min(line_end, tokens.len - 1)

    var tag_count = 0
    var expr_count = 0
    var comment_count = 0
    var ws_only = true
    for j in i .. last:
      case tokens[j].kind
      of hText:
        if not is_whitespace_text(tokens[j]):
          ws_only = false
      of hExpr, hExprRaw:
        inc expr_count
      of hComment:
        inc comment_count
      else:
        inc tag_count

    let standalone = ws_only and expr_count == 0 and
                     (tag_count == 1 or (tag_count == 0 and comment_count > 0))
    if standalone:
      var indent = ""
      for j in i .. last:
        if tokens[j].kind in {hBlockOpen, hInverseOpen, hElse, hBlockClose, hPartial}:
          break
        if tokens[j].kind == hText:
          indent.add(tokens[j].text)
      for j in i .. last:
        if tokens[j].kind == hText:
          tokens[j].text = ""
        elif tokens[j].kind == hPartial:
          tokens[j].indent = indent
    i = last + 1

proc apply_tilde_trims(tokens: var seq[HToken]) =
  ## {{~tag}}: strip trailing whitespace of preceding text;
  ## {{tag~}}: strip leading whitespace of following text.
  for i in 0 ..< tokens.len:
    if tokens[i].kind == hText:
      continue
    if tokens[i].trim_left:
      var j = i - 1
      while j >= 0 and tokens[j].kind == hText:
        tokens[j].text = tokens[j].text.strip(leading = false, trailing = true,
                                              chars = {' ', '\t', '\r', '\n'})
        if tokens[j].text.len > 0:
          break
        dec j
    if tokens[i].trim_right:
      var j = i + 1
      while j < tokens.len and tokens[j].kind == hText:
        tokens[j].text = tokens[j].text.strip(leading = true, trailing = false,
                                              chars = {' ', '\t', '\r', '\n'})
        if tokens[j].text.len > 0:
          break
        inc j

proc lex_handlebars*(input: string): seq[HToken] =
  var tokens = tokenize(input)
  strip_standalone(tokens)
  apply_tilde_trims(tokens)
  # Drop comments and empty texts, merge adjacent texts
  for t in tokens:
    case t.kind
    of hComment:
      continue
    of hText:
      if t.text.len == 0:
        continue
      if result.len > 0 and result[^1].kind == hText:
        result[^1].text.add(t.text)
        continue
      result.add(t)
    else:
      result.add(t)
