import src/liquid/lexer
import src/liquid/parser  
import src/liquid/renderer
import json

let tmpl = "{% assign i = 1 %}{% echo product.tags[i] %}"
let context = %*{"product": {"tags": ["sports", "garden"]}}

let sections = lex(tmpl)
let parsedSections = parse(sections)
let result = renderSections(parsedSections, context)
echo "Result: '", result, "'"
