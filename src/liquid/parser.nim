import tables

import types, parser/[init, core]

let parser = initParser(@[])

proc parseOutputSection(p: Parser): Node =
  result = Node(kind: nkOutput, children: @[p.parseExpression()])

proc parseTagSection(p: Parser): Node =
  let tagName = p.current().value
  var handler: TagHandler

  if tagName in p.tagHandlerLookup:
    handler = p.tagHandlerLookup[tagName]
    p.handlerStack.add(handler)
  elif p.handlerStack.len > 0:
    handler = p.handlerStack[^1]
  else:
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
  for section in sections:
    if section.sectionType == Text:
      continue
    
    section.ast = parseSection(section, strict)
  return sections

when isMainModule and not defined(release):
  import unittest
  include ../../test/parser
