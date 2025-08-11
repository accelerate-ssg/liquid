import types, lexer/[sections,tags]
import strutils

proc lex*(input: string): seq[Section] =
  result = lexSections(input)

  for section in result:
    if section.sectionType == Text:
      continue
    
    # Check if this is a liquid tag that needs newline preservation
    let preserveNewlines = section.sectionType == Tag and section.content.strip().startsWith("liquid")
    section.tokens = lexTagSection(section.content, preserveNewlines)
