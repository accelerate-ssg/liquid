import strutils, sequtils

import ../types, helpers

proc peek(l: Lexer, next: string): bool =
  l.matchesAt(next)

proc peek_and_advance(l: var Lexer, s: string): bool =
  if l.matchesAt(s):
    discard l.advanceBulk(s.len)
    return true
  false


# DFA helper templates for small, reusable pieces
template skipWhitespace(lexer: var Lexer) =
  while lexer.position < input.len and input[lexer.position] in {' ', '\t', '\r', '\n'}:
    discard lexer.advance

template consumeChar(lexer: var Lexer): char =
  let ch = input[lexer.position]
  currentSection.content.add(ch)
  discard lexer.advance
  ch

# Optimized text content handling template - inlined for performance
template handleTextContent() =
  if currentSection == nil:
    startNewSection(Text)
  
  # Single-pass scan for next tag boundary
  var nextTagPos = -1
  for i in lexer.position..<input.len-1:
    if input[i] == '{' and (input[i+1] == '{' or input[i+1] == '%'):
      nextTagPos = i
      break
  
  if nextTagPos > lexer.position:
    # Read all text until next tag
    currentSection.content.add(lexer.advanceBulk(nextTagPos - lexer.position))
  elif nextTagPos == -1:
    # No more tags - consume rest
    currentSection.content.add(lexer.advanceBulk(input.len - lexer.position))
  else:
    # Single character
    currentSection.content.add(lexer.advance)

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
        # Don't strip raw tags since they preserve whitespace
        if not (currentSection.sectionType == Tag and currentSection.content.startsWith("raw ")):
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
        # Pure tokenization using sliding window
        if lexer.position + 2 <= input.len:
          let window = lexer.getWindow(2)
          case window
          of "{{":
            discard lexer.advanceBulk(2)
            startNewSection(Output)
            currentSection.stripLeft = lexer.peek == '-' and (discard lexer.advance; true)
          of "{%":
            discard lexer.advanceBulk(2)
            startNewSection(Tag)
            currentSection.stripLeft = lexer.peek == '-' and (discard lexer.advance; true)
            
            # Character-by-character DFA for fast-path detection
            if lexer.position < input.len:
              case input[lexer.position]
              of '#':
                # Inline comment: {%# ... %}
                discard consumeChar(lexer)
                let scanResult = lexer.scanToPatterns(["-%}", "%}"])
                currentSection.content.add(scanResult.content)
                if scanResult.found:
                  currentSection.stripRight = scanResult.patternIndex == 0
                  if currentSection.stripRight:
                    discard lexer.advanceBulk(3)
                  else:
                    discard lexer.advanceBulk(2)
                  closeCurrentSection()
                  inString = false
              of 'r':
                # Check for 'raw' one character at a time
                if lexer.position + 1 < input.len and input[lexer.position + 1] == 'a':
                  if lexer.position + 2 < input.len and input[lexer.position + 2] == 'w':
                    if lexer.position + 3 < input.len and input[lexer.position + 3] in {' ', '-', '%'}:
                      # Raw block: {% raw %}
                      currentSection.content.add("raw")
                      discard lexer.advanceBulk(3)
                      let closeScan = lexer.scanToPatterns(["-%}", "%}"])
                      currentSection.content.add(closeScan.content)
                      if closeScan.found:
                        currentSection.stripRight = closeScan.patternIndex == 0
                        if currentSection.stripRight:
                          discard lexer.advanceBulk(3)
                        else:
                          discard lexer.advanceBulk(2)
                        closeCurrentSection()
                        inString = false
                        # Handle raw content (existing logic...)
                        var endrawFound = false
                        while lexer.position < input.len:
                          if lexer.matchesAt("{%") or lexer.matchesAt("{%-"):
                            let savePos = lexer.position
                            let stripLeft = lexer.matchesAt("{%-")
                            if stripLeft:
                              discard lexer.advanceBulk(3)
                            else:
                              discard lexer.advanceBulk(2)
                            skipWhitespace(lexer)
                            if lexer.matchesAt("endraw"):
                              discard lexer.advanceBulk(6)
                              skipWhitespace(lexer)
                              if lexer.matchesAt("-%}") or lexer.matchesAt("%}"):
                                let stripRight = lexer.matchesAt("-%}")
                                if stripRight:
                                  discard lexer.advanceBulk(3)
                                else:
                                  discard lexer.advanceBulk(2)
                                let rawContent = input[savePos..<lexer.position - (if stripRight: 3 else: 2) - 6]
                                if rawContent.len > 0:
                                  currentSection = Section(sectionType: Text, content: rawContent, startRow: 0, startCol: 0)
                                  sections.add(currentSection)
                                  currentSection = nil
                                currentSection = Section(sectionType: Tag, content: "endraw", stripLeft: stripLeft, stripRight: stripRight, startRow: lexer.line, startCol: lexer.column)
                                sections.add(currentSection)
                                currentSection = nil
                                endrawFound = true
                                break
                              else:
                                lexer.position = savePos
                                if currentSection == nil: startNewSection(Text)
                                currentSection.content.add(lexer.advance)
                            else:
                              lexer.position = savePos
                              if currentSection == nil: startNewSection(Text)
                              currentSection.content.add(lexer.advance)
                          else:
                            if currentSection == nil: startNewSection(Text)
                            currentSection.content.add(lexer.advance)
                    else:
                      discard consumeChar(lexer)
                  else:
                    discard consumeChar(lexer)
                else:
                  discard consumeChar(lexer)
              of 'c':
                # Check for 'comment' one character at a time  
                if lexer.position + 1 < input.len and input[lexer.position + 1] == 'o':
                  if lexer.position + 2 < input.len and input[lexer.position + 2] == 'm':
                    if lexer.position + 3 < input.len and input[lexer.position + 3] == 'm':
                      if lexer.position + 4 < input.len and input[lexer.position + 4] == 'e':
                        if lexer.position + 5 < input.len and input[lexer.position + 5] == 'n':
                          if lexer.position + 6 < input.len and input[lexer.position + 6] == 't':
                            if lexer.position + 7 < input.len and input[lexer.position + 7] in {' ', '-', '%'}:
                              # Comment block: {% comment %}
                              currentSection.content.add("comment")
                              discard lexer.advanceBulk(7)
                              let closeScan = lexer.scanToPatterns(["-%}", "%}"])
                              currentSection.content.add(closeScan.content)
                              if closeScan.found:
                                currentSection.stripRight = closeScan.patternIndex == 0
                                if currentSection.stripRight:
                                  discard lexer.advanceBulk(3)
                                else:
                                  discard lexer.advanceBulk(2)
                                closeCurrentSection()
                                inString = false
                                # Handle comment content (scan to endcomment and discard)
                                while lexer.position < input.len:
                                  if lexer.matchesAt("{%") or lexer.matchesAt("{%-"):
                                    let savePos = lexer.position
                                    let stripLeft = lexer.matchesAt("{%-")
                                    if stripLeft:
                                      discard lexer.advanceBulk(3)
                                    else:
                                      discard lexer.advanceBulk(2)
                                    skipWhitespace(lexer)
                                    if lexer.matchesAt("endcomment"):
                                      discard lexer.advanceBulk(10)
                                      skipWhitespace(lexer)
                                      if lexer.matchesAt("-%}") or lexer.matchesAt("%}"):
                                        let stripRight = lexer.matchesAt("-%}")
                                        if stripRight:
                                          discard lexer.advanceBulk(3)
                                        else:
                                          discard lexer.advanceBulk(2)
                                        currentSection = Section(sectionType: Tag, content: "endcomment", stripLeft: stripLeft, stripRight: stripRight, startRow: lexer.line, startCol: lexer.column)
                                        sections.add(currentSection)
                                        currentSection = nil
                                        break
                                      else:
                                        lexer.position = savePos
                                        discard lexer.advance
                                    else:
                                      lexer.position = savePos
                                      discard lexer.advance
                                  else:
                                    discard lexer.advance
                            else:
                              discard consumeChar(lexer)
                          else:
                            discard consumeChar(lexer)
                        else:
                          discard consumeChar(lexer)
                      else:
                        discard consumeChar(lexer)
                    else:
                      discard consumeChar(lexer)
                  else:
                    discard consumeChar(lexer)
                else:
                  discard consumeChar(lexer)
              else:
                discard consumeChar(lexer)
          else:
            # Regular text
            handleTextContent()
        else:
          # Regular text
          handleTextContent()
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
        
        if currentSection.sectionType == Output:
          if lexer.position + 2 <= input.len:
            let window = lexer.getWindow(3)
            if window.startsWith("}}") or window.startsWith("-}}"):
              currentSection.stripRight = window[0] == '-'
              if currentSection.stripRight:
                discard lexer.advance
              discard lexer.advanceBulk(2)
              closeCurrentSection()
              inString = false
            else:
              currentSection.content.add(lexer.advance)
          else:
            currentSection.content.add(lexer.advance)
        elif currentSection.sectionType == Tag:
          if lexer.position + 2 <= input.len:
            let window = lexer.getWindow(3)
            if window.startsWith("%}") or window.startsWith("-%}"):
              currentSection.stripRight = window[0] == '-'
              if currentSection.stripRight:
                discard lexer.advance
              discard lexer.advanceBulk(2)
              closeCurrentSection()
              inString = false
            else:
              currentSection.content.add(lexer.advance)
          else:
            currentSection.content.add(lexer.advance)
        elif not inString and (lexer.peek("{{") or lexer.peek("{%")):
          raise newException(LexerError, "Unbalanced brackets: Found new opening tag before closing tag opened at line " & 
            $currentSection.startRow & " column " & $currentSection.startCol)
        else:
          # If we don't have a current section, start a new text section
          if currentSection == nil:
            startNewSection(Text)
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
