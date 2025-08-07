import src/liquid/lexer
import src/liquid/parser  
import src/liquid/parser/to_string

let tmpl = "{% for i in (1..6), limit: 4, offset: 2 %}{{ i }} {% endfor %}"

let sections = lex(tmpl)
let parsedSections = parse(sections)

for section in parsedSections:
  echo $section.ast
  echo "---"
