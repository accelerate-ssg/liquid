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

proc findNextEndrawPattern(l: Lexer): int =
  # Returns the position where the endraw pattern starts, or -1 if not found
  var pos = l.position
  let search_text = l.input[pos..^1]
  
  # Check for all possible endraw patterns and find the earliest one
  let patterns = @[
    "{% endraw %}",      # 12 chars
    "{%- endraw %}",     # 14 chars 
    "{% endraw -%}",     # 14 chars
    "{%- endraw -%}"     # 16 chars
  ]
  
  var earliest_pos = -1
  for pattern in patterns:
    let pattern_pos = search_text.find(pattern)
    if pattern_pos != -1:
      let absolute_pos = pos + pattern_pos
      if earliest_pos == -1 or absolute_pos < earliest_pos:
        earliest_pos = absolute_pos
  
  return earliest_pos

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
          # Check if this is a comment tag that contains nested liquid syntax
          let savedPos = lexer.position
          let savedLine = lexer.line
          let savedCol = lexer.column
          discard lexer.peek_and_advance("{%-")
          # Skip any whitespace
          while lexer.position < input.len and lexer.input[lexer.position] in {' ', '\t'}:
            discard lexer.advance()
          if lexer.position < input.len and lexer.input[lexer.position] == '#':
            # This is a comment with whitespace control {%- # ...
            # Check if it contains nested tags by looking ahead for {%
            var lookaheadPos = lexer.position + 1
            var hasNestedTags = false
            while lookaheadPos < input.len and not (lookaheadPos + 2 <= input.len and input[lookaheadPos..<lookaheadPos+2] == "-%}"):
              if lookaheadPos + 2 <= input.len and input[lookaheadPos..<lookaheadPos+2] == "{%":
                hasNestedTags = true
                break
              lookaheadPos += 1
            
            if hasNestedTags:
              # This comment contains nested tags - consume everything until the first %} as a comment
              # then output any remaining text
              lexer.position = savedPos
              lexer.line = savedLine
              lexer.column = savedCol
              discard lexer.peek_and_advance("{%-")
              
              # Consume everything until we find the first %} (which closes the nested tag)
              while lexer.position < input.len and not lexer.peek("%}"):
                discard lexer.advance()
              
              # Skip the %}
              if lexer.peek("%}"):
                discard lexer.peek_and_advance("%}")
                
                # Now create a text section for any remaining content  
                startNewSection(Text)
                while lexer.position < input.len:
                  currentSection.content.add(lexer.advance)
              # Don't create any section for the comment itself - it's consumed
            else:
              # Normal comment tag without nested syntax
              lexer.position = savedPos
              lexer.line = savedLine
              lexer.column = savedCol
              discard lexer.peek_and_advance("{%")
              startNewSection(Tag)
              currentSection.stripLeft = lexer.peek_and_advance("-")
          else:
            # Normal tag with whitespace control
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
          
          # Special handling for raw tag - capture everything until endraw
          if currentSection.content.strip() == "raw":
            # Don't close the section yet - we need to capture the raw content
            inString = false
            
            # Capture raw content until we find endraw
            let endrawPos = findNextEndrawPattern(lexer)
            var rawContent = ""
            if endrawPos != -1:
              # Extract everything from current position to endraw position
              rawContent = input[lexer.position..<endrawPos]
              # Move lexer position to the start of endraw
              for i in lexer.position..<endrawPos:
                discard lexer.advance()
            else:
              # No endraw found - consume everything
              while lexer.position < input.len:
                rawContent.add(lexer.advance)
            
            # Store the raw content in the current section's content
            # The parser will extract this and create the proper AST
            currentSection.content = "raw " & rawContent
            
            # Now consume the endraw tag without creating a new section
            if lexer.position < input.len:
              # Determine which endraw pattern we're consuming and handle whitespace control
              let remaining_input = input[lexer.position..^1]
              var trim_following = false
              
              if remaining_input.startsWith("{%- endraw -%}"):
                lexer.position += 14  # "{%- endraw -%}" is 14 characters, not 16
                trim_following = true  # The -%} means trim following whitespace
              elif remaining_input.startsWith("{%- endraw %}"):
                lexer.position += 14
              elif remaining_input.startsWith("{% endraw -%}"):
                lexer.position += 14
                trim_following = true  # The -%} means trim following whitespace
              elif remaining_input.startsWith("{% endraw %}"):
                lexer.position += 12
              
              # Handle whitespace trimming if -%} was used
              if trim_following:
                while lexer.position < input.len and input[lexer.position] in {' ', '\t', '\r', '\n'}:
                  lexer.position += 1
            
            closeCurrentSection()
          else:
            closeCurrentSection()
            inString = false  # Reset string state when section closes
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
