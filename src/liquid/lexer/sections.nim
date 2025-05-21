import strutils, sequtils

import ../types, helpers

proc peek(l: Lexer, next: string): bool =
  if l.position + next.len <= l.input.len and l.input[l.position..<l.position+next.len] == next:
    return true
  false

proc peek_and_advance(l: var Lexer, s: string): bool =
  if l.peek(s):
    for ch in s:
      if ch == '\n':
        l.line += 1
        l.column = 0
      else:
        l.column += 1
    l.position += s.len
    return true
  false

template with(self: SectionLexer, body: untyped) =
  template lexer: untyped = self.lexer
  template inSpecialSection: untyped = self.inSpecialSection
  template currentSection: untyped = self.currentSection
  template openBrackets: untyped = self.openBrackets
  template sections: untyped = self.sections
  template closeCurrentSection(): untyped = self.closeCurrentSection()
  template startNewSection(sectionType: SectionType): untyped = self.startNewSection(sectionType)
    
  body

proc initSectionLexer(input: string): SectionLexer =
  SectionLexer(
    lexer: initLexer(input),
    inSpecialSection: false,
    currentSection: nil,
    openBrackets: 0,
    sections: @[]
  )

proc closeCurrentSection(sectionLexer: SectionLexer) =
  with sectionLexer:
    if currentSection == nil: return
    if currentSection.content.len > 0:
      currentSection.endRow = lexer.line
      currentSection.endCol = lexer.column - 1
      if currentSection.sectionType in {Output, Tag}:
        currentSection.content = currentSection.content.strip()
        openBrackets -= 1
      
      sections.add(currentSection)
      inSpecialSection = false
      currentSection = nil

proc startNewSection(sectionLexer: SectionLexer, sectionType: SectionType) =
  with sectionLexer:
    closeCurrentSection()
    currentSection = Section(
      sectionType: sectionType,
      startRow: lexer.line,
      startCol: if sectionType == Text: lexer.column else: lexer.column - 2
    )
    inSpecialSection = sectionType != Text
    if inSpecialSection:
      openBrackets += 1

proc lexSections*(input: string): seq[Section] =
  var
    sectionLexer = initSectionLexer(input)

  with sectionLexer:
    while lexer.position < input.len:
      if not inSpecialSection:
        if lexer.peek_and_advance("{{"):
          startNewSection(Output)
          currentSection.stripLeft = lexer.peek_and_advance("-")
        elif lexer.peek_and_advance("{%"):
          startNewSection(Tag)
          currentSection.stripLeft = lexer.peek_and_advance("-")
        else:
          if currentSection == nil:
            startNewSection(Text)
          currentSection.content.add(lexer.advance)
      else:
        if currentSection.sectionType == Output and (lexer.peek("}}") or lexer.peek("-}}")):
          currentSection.stripRight = lexer.peek_and_advance("-")
          discard lexer.peek_and_advance("}}")
          closeCurrentSection()
        elif currentSection.sectionType == Tag and (lexer.peek("%}") or lexer.peek("-%}")):
          currentSection.stripRight = lexer.peek_and_advance("-")
          discard lexer.peek_and_advance("%}")
          closeCurrentSection()
        elif lexer.peek("{{") or lexer.peek("{%"):
          raise newException(LexerError, "Unbalanced brackets: Found new opening tag before closing tag opened at line " & 
            $currentSection.startRow & " column " & $currentSection.startCol)
        else:
          currentSection.content.add(lexer.advance)

    if currentSection != nil and currentSection.sectionType == Text:
      closeCurrentSection()

    if openBrackets > 0:

      raise newException(LexerError, "Unbalanced brackets: Missing closing tag for tag opened at line " & 
        $currentSection.startRow & " column " & $currentSection.startCol)

    if input.strip().len > 0 and sections.len == 0:
      raise newException(ValueError, "Unclosed section")

    return sections

proc `$`*(section: Section): string =
  "Type: " & $section.sectionType & "\n" &
  "Content: " & repr(section.content) & "\n" &
  $section.startRow & ":" & $section.startCol & " - " & 
  $section.endRow & ":" & $section.endCol & "\n" &
  "Strip Left: " & $section.stripLeft & "\n" &
  "Strip Right: " & $section.stripRight

proc `$`*(sections: seq[Section]): string =
  sections.mapIt($it).join("\n\n")

when isMainModule and not defined(release):
  import unittest
  include ../../../test/lexers/sections
