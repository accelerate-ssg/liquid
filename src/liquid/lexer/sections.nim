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
  template inString: untyped = self.inString
  template stringDelimiter: untyped = self.stringDelimiter
  template closeCurrentSection(): untyped = self.closeCurrentSection()
  template startNewSection(sectionType: SectionType): untyped = self.startNewSection(sectionType)
    
  body

proc initSectionLexer(input: string): SectionLexer =
  SectionLexer(
    lexer: initLexer(input),
    inSpecialSection: false,
    currentSection: nil,
    openBrackets: 0,
    sections: @[],
    inString: false,
    stringDelimiter: ' '
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
        elif lexer.peek("{%#"):
          # Check if this is a true inline comment (without whitespace control)
          let savedPos = lexer.position
          let savedLine = lexer.line
          let savedCol = lexer.column
          discard lexer.peek_and_advance("{%#")
          # Consume content until we find %} or -%}
          var hasWhitespaceControl = false
          while lexer.position < input.len:
            if lexer.peek("-%}"):
              hasWhitespaceControl = true
              break
            elif lexer.peek("%}"):
              break
            else:
              discard lexer.advance()
          
          if hasWhitespaceControl:
            # This is {%# ... -%} which should be treated as a tag, not inline comment
            lexer.position = savedPos
            lexer.line = savedLine
            lexer.column = savedCol
            discard lexer.peek_and_advance("{%")
            startNewSection(Tag)
            currentSection.stripLeft = false  # {%# doesn't have initial whitespace control
          else:
            # True inline comment {%# ... %} - consume and emit nothing
            discard lexer.peek_and_advance("%}")
            # Don't create any section - just continue
        elif lexer.peek("{%-"):
          # Check if this is the specific invalid pattern that should fallback to text
          let savedPos = lexer.position
          let savedLine = lexer.line
          let savedCol = lexer.column
          discard lexer.peek_and_advance("{%-")
          # Skip any whitespace
          while lexer.position < input.len and lexer.input[lexer.position] in {' ', '\t'}:
            discard lexer.advance()
          if lexer.position < input.len and lexer.input[lexer.position] == '#' and lexer.peek("{%"):
            # This is the specific pattern {%- # {% that should fallback to text
            # Restore position and treat as text
            lexer.position = savedPos
            lexer.line = savedLine
            lexer.column = savedCol
            # Find the content that should be output as text
            discard lexer.peek_and_advance("{%-")
            # Skip until we find the actual tag content
            while lexer.position < input.len and lexer.input[lexer.position] in {' ', '\t', '#'}:
              discard lexer.advance()
            # Skip to after the nested tag
            if lexer.peek("{%"):
              var bracketCount = 1
              discard lexer.peek_and_advance("{%")
              while lexer.position < input.len and bracketCount > 0:
                if lexer.peek("{%"):
                  bracketCount += 1
                  discard lexer.peek_and_advance("{%")
                elif lexer.peek("%}"):
                  bracketCount -= 1
                  discard lexer.peek_and_advance("%}")
                else:
                  discard lexer.advance()
            # Now we should be at the content that needs to be output
            if currentSection == nil:
              startNewSection(Text)
            # Add the remaining content until -%}
            while lexer.position < input.len and not lexer.peek("-%}"):
              currentSection.content.add(lexer.advance)
            # Skip the -%}
            discard lexer.peek_and_advance("-%}")
          else:
            # Normal tag with whitespace control (including {%- #comment -%})
            lexer.position = savedPos
            lexer.line = savedLine
            lexer.column = savedCol
            discard lexer.peek_and_advance("{%")
            startNewSection(Tag)
            currentSection.stripLeft = lexer.peek_and_advance("-")
        elif lexer.peek_and_advance("{%"):
          startNewSection(Tag)
          currentSection.stripLeft = lexer.peek_and_advance("-")
        else:
          if currentSection == nil:
            startNewSection(Text)
          currentSection.content.add(lexer.advance)
      else:
        # Track string state inside special sections
        if lexer.position < input.len:
          let ch = lexer.input[lexer.position]
          if not inString and (ch == '"' or ch == '\''): 
            inString = true
            stringDelimiter = ch
          elif inString and ch == stringDelimiter:
            # Check if escaped
            if lexer.position > 0 and lexer.input[lexer.position - 1] != '\\':
              inString = false
        
        if currentSection.sectionType == Output and (lexer.peek("}}") or lexer.peek("-}}")):
          currentSection.stripRight = lexer.peek_and_advance("-")
          discard lexer.peek_and_advance("}}")
          closeCurrentSection()
          inString = false  # Reset string state when section closes
        elif currentSection.sectionType == Tag and (lexer.peek("%}") or lexer.peek("-%}")):
          currentSection.stripRight = lexer.peek_and_advance("-")
          discard lexer.peek_and_advance("%}")
          closeCurrentSection()
          inString = false  # Reset string state when section closes
        elif not inString and (lexer.peek("{{") or lexer.peek("{%")):
          raise newException(LexerError, "Unbalanced brackets: Found new opening tag before closing tag opened at line " & 
            $currentSection.startRow & " column " & $currentSection.startCol)
        else:
          currentSection.content.add(lexer.advance)

    if currentSection != nil and currentSection.sectionType == Text:
      closeCurrentSection()

    if openBrackets > 0:

      raise newException(LexerError, "Unbalanced brackets: Missing closing tag for tag opened at line " & 
        $currentSection.startRow & " column " & $currentSection.startCol)

    # Only raise "Unclosed section" if input has non-comment content but no sections
    # Inline comments like {%# ... %} should not trigger this error
    if input.strip().len > 0 and sections.len == 0:
      # Check if the input is just an inline comment
      let stripped = input.strip()
      if not (stripped.startsWith("{%#") and stripped.endsWith("%}")):
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
