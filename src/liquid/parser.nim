import tables, strutils

import types, parser/[init, core]

let parser = initParser(@[])

proc parseOutputSection(p: Parser): Node =
  result = Node(kind: nkOutput, children: @[p.parseExpression()])

proc parseTagSection(p: Parser): Node =
  let tagName = p.current().value
  var handler: TagHandler
  var handlerInfo: TagHandlerInfo
  var found = false

  # Look for a handler that matches this tag name
  for info, h in p.tagHandlerLookup:
    if info.opening_tag == tagName:
      handler = h
      handlerInfo = info
      found = true
      if info.block_tag:
        p.handlerStack.add(handler)
      break

  if not found and p.handlerStack.len > 0:
    # Check if this is a block separator or end tag for the current handler
    for info, h in p.tagHandlerLookup:
      if p.handlerStack[^1] == h:
        # Check if it's a valid block separator
        if tagName in info.inner_tags:
          handler = h
          found = true
          break
        # Check if it's a valid end tag (generic "end" or "end" + opening_tag)
        let isGenericEnd = tagName == "end" or tagName == "end" & info.opening_tag
        if isGenericEnd:
          handler = h
          found = true
          break

  if not found:
    raise newException(ValueError, "1 Unsupported tag: " & tagName)

  result = handler(p)

  if result.isNil:
    raise newException(ValueError, "2 Unsupported tag: " & tagName)

  if result.kind == nkEnd:
    discard p.handlerStack.pop()

proc parseSection*(section: Section, strict: bool): Node =
  parser.tokens = section.tokens
  parser.position = 0
  parser.strict_mode = strict
  case section.sectionType
  of Output: result = parser.parseOutputSection()
  of Tag: result = parser.parseTagSection()
  of Text: raise newException(ValueError, "Text sections should not be parsed")

proc parse*(sections: seq[Section], strict: bool = false): seq[Section] =
  var i = 0
  while i < sections.len:
    let section = sections[i]
    if section.sectionType == Text:
      inc i
      continue
    
    section.ast = parseSection(section, strict)
    
    # Special handling for raw tags - extract content from rawContent field
    if section.ast != nil and section.ast.kind == nkTag and section.ast.tagName == "raw":
      # Check if the section has raw content in the special field
      if section.rawContent.len > 0:
        section.ast.parameters = @[Node(kind: nkString, strVal: section.rawContent)]
      # Legacy handling - check if section content has embedded raw content ("raw <content>")
      elif section.content.startsWith("raw "):
        let rawContent = section.content[4..^1]  # Skip "raw " prefix
        section.ast.parameters = @[Node(kind: nkString, strVal: rawContent)]
      # Legacy handling - check if next section is text (the raw content)
      elif i + 1 < sections.len and sections[i + 1].sectionType == Text:
        let rawContent = sections[i + 1].content
        section.ast.parameters = @[Node(kind: nkString, strVal: rawContent)]
        # Skip the text section since we've consumed it
        inc i
    
    inc i
  return sections

when isMainModule and not defined(release):
  import unittest
  include ../../test/parser
