import src/liquid/lexer
import src/liquid/parser  
import src/liquid/parser/to_string
import json

let tmpl = "{% echo product.tags[i] %}"

let sections = lex(tmpl)
let parsedSections = parse(sections)

for section in parsedSections:
  echo $section.ast
