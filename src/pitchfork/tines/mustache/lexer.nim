# Mustache lexer
# ==============
# Tokenizes Mustache source into a flat token stream, handling:
# - variable interpolation:   {{name}}, {{a.b.c}}, {{.}}
# - unescaped interpolation:  {{{name}}}, {{& name}}
# - sections:                 {{#name}} ... {{/name}}
# - inverted sections:        {{^name}} ... {{/name}}
# - partials:                 {{> name}}
# - comments:                 {{! ... }}
# - delimiter changes:        {{=<% %>=}}
# - spec-conformant standalone-line whitespace stripping, including
#   indentation capture for standalone partials.

import std/strutils

type
  MTokenKind* = enum
    mText          # Literal template text
    mVariable      # {{name}} — HTML-escaped interpolation
    mUnescaped     # {{{name}}} / {{& name}} — raw interpolation
    mSectionOpen   # {{#name}}
    mInvertedOpen  # {{^name}}
    mSectionClose  # {{/name}}
    mPartial       # {{> name}}

  MToken* = object
    case kind*: MTokenKind
    of mText:
      text*: string
    of mPartial:
      partial_name*: string
      indent*: string   # Standalone indentation, applied to partial output
    else:
      name*: seq[string]  # Dotted name segments; ["."] = implicit iterator

const default_open = "{{"
const default_close = "}}"

proc split_name(raw: string): seq[string] =
  ## Split a dotted mustache name into segments. "." stays as ["."]
  let trimmed = raw.strip()
  if trimmed == ".":
    return @["."]
  result = trimmed.split('.')

proc lex_error(msg: string, pos: int): ref ValueError =
  newException(ValueError, "Mustache lex error at offset " & $pos & ": " & msg)

proc tokenize(input: string): seq[MToken] =
  ## First pass: raw token stream. Text tokens are split after every
  ## newline so the standalone pass can reason about lines.
  var open_delim = default_open
  var close_delim = default_close
  var pos = 0
  var text = ""

  template flush_text() =
    if text.len > 0:
      result.add(MToken(kind: mText, text: text))
      text = ""

  while pos < input.len:
    if pos + open_delim.len <= input.len and
       input.continuesWith(open_delim, pos):
      # Triple mustache is only meaningful with the default delimiters
      let is_triple = open_delim == default_open and
                      pos + 2 < input.len and input[pos + 2] == '{'
      flush_text()
      if is_triple:
        let close_seq = "}" & default_close  # "}}}"
        let stop = input.find(close_seq, pos + 3)
        if stop < 0:
          raise lex_error("unclosed '{{{'", pos)
        result.add(MToken(kind: mUnescaped, name: split_name(input[pos + 3 ..< stop])))
        pos = stop + close_seq.len
        continue

      let content_start = pos + open_delim.len
      if content_start >= input.len:
        raise lex_error("unclosed tag", pos)

      let sigil = input[content_start]
      if sigil == '=':
        # Delimiter change: {{=<% %>=}}
        let close_seq = "=" & close_delim
        let stop = input.find(close_seq, content_start + 1)
        if stop < 0:
          raise lex_error("unclosed delimiter tag", pos)
        let parts = input[content_start + 1 ..< stop].strip().splitWhitespace()
        if parts.len != 2:
          raise lex_error("malformed delimiter tag", pos)
        pos = stop + close_seq.len
        open_delim = parts[0]
        close_delim = parts[1]
        # Represented as a zero-width text token so the standalone pass
        # can strip the line it stands on
        result.add(MToken(kind: mText, text: ""))
        continue

      let stop = input.find(close_delim, content_start)
      if stop < 0:
        raise lex_error("unclosed tag", pos)
      let inner = input[content_start ..< stop]
      pos = stop + close_delim.len

      case sigil
      of '!':
        # Comment: zero-width placeholder, strippable when standalone
        result.add(MToken(kind: mText, text: ""))
      of '#':
        result.add(MToken(kind: mSectionOpen, name: split_name(inner[1..^1])))
      of '^':
        result.add(MToken(kind: mInvertedOpen, name: split_name(inner[1..^1])))
      of '/':
        result.add(MToken(kind: mSectionClose, name: split_name(inner[1..^1])))
      of '>':
        result.add(MToken(kind: mPartial, partial_name: inner[1..^1].strip(), indent: ""))
      of '&':
        result.add(MToken(kind: mUnescaped, name: split_name(inner[1..^1])))
      else:
        result.add(MToken(kind: mVariable, name: split_name(inner)))
    else:
      text.add(input[pos])
      if input[pos] == '\n':
        flush_text()
      inc pos
  flush_text()

proc is_whitespace_text(t: MToken): bool =
  t.kind == mText and t.text.allCharsInSet({' ', '\t', '\r', '\n'})

proc strip_standalone(tokens: seq[MToken]): seq[MToken] =
  ## Second pass: spec standalone-line handling. A line whose only
  ## non-whitespace content is exactly one section/close/partial tag
  ## (or a comment/delimiter tag, already reduced to a zero-width text
  ## token by tokenize) has its surrounding whitespace and line ending
  ## removed. For partials the leading whitespace becomes the indent.
  var tokens = tokens
  var i = 0
  while i < tokens.len:
    # Collect one line: tokens up to and including a text token that
    # ends with '\n' (texts are pre-split at newlines), or end of input.
    var line_end = i
    while line_end < tokens.len:
      if tokens[line_end].kind == mText and tokens[line_end].text.endsWith("\n"):
        break
      inc line_end
    let last = min(line_end, tokens.len - 1)

    # Standalone-eligible tags on this line; comments/delimiter tags have
    # already been reduced to zero-width texts, which are strippable if
    # the rest of the line is whitespace and no other tag is present.
    var tag_count = 0        # section/close/partial tags
    var other_tag_count = 0  # variables/unescaped — never standalone
    var zero_width = 0       # comment/delimiter placeholders
    var ws_only = true
    for j in i .. last:
      case tokens[j].kind
      of mText:
        if tokens[j].text.len == 0:
          inc zero_width
        elif not is_whitespace_text(tokens[j]):
          ws_only = false
      of mVariable, mUnescaped:
        inc other_tag_count
      else:
        inc tag_count

    let standalone = ws_only and other_tag_count == 0 and
                     (tag_count == 1 or (tag_count == 0 and zero_width > 0))
    if standalone:
      # Gather the indentation (whitespace before the tag) for partials,
      # then blank out every text token on the line.
      var indent = ""
      for j in i .. last:
        if tokens[j].kind in {mSectionOpen, mInvertedOpen, mSectionClose, mPartial}:
          break
        if tokens[j].kind == mText:
          indent.add(tokens[j].text)
      for j in i .. last:
        if tokens[j].kind == mText:
          tokens[j].text = ""
        elif tokens[j].kind == mPartial:
          tokens[j].indent = indent
    i = last + 1

  # Drop empty text tokens and merge adjacent texts
  for t in tokens:
    if t.kind == mText:
      if t.text.len == 0:
        continue
      if result.len > 0 and result[^1].kind == mText:
        result[^1].text.add(t.text)
        continue
    result.add(t)

proc lex_mustache*(input: string): seq[MToken] =
  strip_standalone(tokenize(input))
