suite "Liquid Template Lexer Tests":

  test "Basic text":
    let input = "Hello, world!"
    let result = lexSections(input)
    check:
      result.len == 1
      result[0].sectionType == Text
      result[0].content == "Hello, world!"
      result[0].startRow == 1
      result[0].startCol == 0
      result[0].endRow == 1
      result[0].endCol == 12

  test "Simple output tag":
    let input = "Hello, {{ name }}!"
    let result = lexSections(input)
    check:
      result.len == 3
      result[0].sectionType == Text
      result[0].content == "Hello, "
      result[1].sectionType == Output
      result[1].content == "name"
      result[2].sectionType == Text
      result[2].content == "!"

  test "Simple control tag":
    let input = "{% if condition %}True{% endif %}"
    let result = lexSections(input)
    check:
      result.len == 3
      result[0].sectionType == Tag
      result[0].content == "if condition"
      result[1].sectionType == Text
      result[1].content == "True"
      result[2].sectionType == Tag
      result[2].content == "endif"

  test "Whitespace control":
    let input = "{%- for item in items -%}\n  {{ item }}\n{%- endfor -%}"
    let result = lexSections(input)
    check:
      result.len == 5
      result[0].sectionType == Tag
      result[0].stripLeft == true
      result[0].stripRight == true
      result[1].sectionType == Text
      result[1].content == "\n  "
      result[2].sectionType == Output
      result[2].content == "item"
      result[2].stripLeft == false
      result[2].stripRight == false
      result[3].sectionType == Text
      result[3].content == "\n"
      result[4].sectionType == Tag
      result[4].stripLeft == true
      result[4].stripRight == true

  test "Nested tags":
    let input = "{% if x %}{% for y in z %}{{ y }}{% endfor %}{% endif %}"
    let result = lexSections(input)
    check:
      result.len == 5
      result.mapIt(it.sectionType) == @[Tag, Tag, Output, Tag, Tag]
      result[0].content == "if x"
      result[1].content == "for y in z"
      result[2].content == "y"
      result[3].content == "endfor"
      result[4].content == "endif"

  test "Mixed content":
    let input = "Start {{ var1 }} middle {% if cond %}{{ var2 }}{% endif %} end"
    let result = lexSections(input)
    check:
      result.len == 7
      result.mapIt(it.sectionType) == @[Text, Output, Text, Tag, Output, Tag, Text]

  test "Empty input":
    let input = ""
    let result = lexSections(input)
    check:
      result.len == 0

  test "Only whitespace":
    let input = "   \n\t   "
    let result = lexSections(input)
    check:
      result.len == 1
      result[0].sectionType == Text
      result[0].content == "   \n\t   "

  test "Unclosed tag":
    let input = "{{ unclosed"
    expect LexerError:
      discard lexSections(input)

    try:
      discard lexSections(input)
    except LexerError as e:
      check e.msg == "Unbalanced brackets: Missing closing tag for tag opened at line 1 column 0"

  test "Unbalanced tags":
    let input = "Hello {{name}}\nThis is {% if true }}{{ unclosed }}{% endif %}"
    expect LexerError:
      discard lexSections(input)

    try:
      discard lexSections(input)
    except LexerError as e:
      check e.msg == "Unbalanced brackets: Found new opening tag before closing tag opened at line 2 column 9"

  test "Escaped characters":
    let input = "{{ 'It''s a string' }}"
    let result = lexSections(input)
    check:
      result.len == 1
      result[0].sectionType == Output
      result[0].content == "'It''s a string'"

  test "Row and column tracking":
    let input = "Line 1\nLine 2 {{ var }}\nLine 3"
    let result = lexSections(input)
    check:
      result.len == 3
      result[0].startRow == 1 and result[0].endRow == 2
      result[1].startRow == 2 and result[1].startCol == 8
      result[2].startRow == 2 and result[2].endRow == 3
