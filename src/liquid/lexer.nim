import types, lexer/[sections,tags]
import strutils

proc lex*(input: string): seq[Section] =
  result = lexSections(input)

  for section in result:
    if section.sectionType == Text:
      continue
    
    # Special handling for raw tags - they have embedded content
    if section.sectionType == Tag and section.content.strip().startsWith("raw "):
      # Extract the raw content more carefully
      let content = section.content
      if content.startsWith("raw "):
        section.rawContent = content[4..^1]  # Everything after "raw "
        section.content = "raw"  # Reset content to just "raw"
        section.tokens = lexTagSection(section.content, false)
    else:
      # Check if this is a liquid tag that needs newline preservation
      let preserveNewlines = section.sectionType == Tag and section.content.strip().startsWith("liquid")
      section.tokens = lexTagSection(section.content, preserveNewlines)
