import types, lexer/[sections,tags]

proc lex*(input: string): seq[Section] =
  result = lexSections(input)

  for section in result:
    if section.sectionType == Text:
      continue
    
    section.tokens = lexTagSection(section.content)
