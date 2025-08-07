import src/liquid/lexer

let tmpl = "{% for i in (1..6), limit: 4, offset: 2 %}{{ i }} {% endfor %}"

let sections = lex(tmpl)

for section in sections:
  echo "Section: ", section.sectionType
  for token in section.tokens:
    echo "  ", token.kind, ": ", token.value
  echo ""
