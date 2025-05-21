suite "Liquid Tag Lexer Tests":

  test "Basic keywords":
    let input = "if else elsif endif unless endunless case when endcase for endfor break continue"
    let tokens = lexTagSection(input)
    check tokens.len == 13
    for token in tokens:
      check token.kind == TkKeyword

  test "Identifiers":
    let input = "variable user.name product.price"
    let tokens = lexTagSection(input)
    check tokens.len == 7
    check tokens[0].kind == TkIdentifier
    check tokens[1].kind == TkIdentifier
    check tokens[2].kind == TkDot
    check tokens[3].kind == TkIdentifier
    check tokens[1].kind == TkIdentifier
    check tokens[2].kind == TkDot
    check tokens[3].kind == TkIdentifier

  test "Numbers":
    let input = "42 3.14 0.5 10"
    let tokens = lexTagSection(input)
    check tokens.len == 4
    for token in tokens:
      check token.kind == TkNumber
    check tokens[0].value == "42"
    check tokens[1].value == "3.14"

  test "Strings":
    let input = "'single quoted' \"double quoted\" 'with \"nested\" quotes'"
    let tokens = lexTagSection(input)
    check tokens.len == 3
    for token in tokens:
      check token.kind == TkString
    check tokens[0].value == "single quoted"
    check tokens[1].value == "double quoted"
    check tokens[2].value == "with \"nested\" quotes"

  test "Operators":
    let input = "== != < <= > >= + - * / %"
    let tokens = lexTagSection(input)
    check tokens.len == 11
    for token in tokens:
      check token.kind == TkOperator

  test "Special characters":
    let input = ". , : | = ( ) [ ] .."
    let tokens = lexTagSection(input)
    check tokens.len == 10
    check tokens[0].kind == TkDot
    check tokens[1].kind == TkComma
    check tokens[2].kind == TkColon
    check tokens[3].kind == TkPipe
    check tokens[4].kind == TkAssign
    check tokens[5].kind == TkLeftParen
    check tokens[6].kind == TkRightParen
    check tokens[7].kind == TkLeftBracket
    check tokens[8].kind == TkRightBracket
    check tokens[9].kind == TkRange

  test "Complex expression":
    let input = "if user.age >= 18 and (user.role == 'admin' or user.permissions contains 'edit')"
    let tokens = lexTagSection(input)
    check tokens.len == 20
    check tokens[0].kind == TkKeyword
    check tokens[0].value == "if"
    check tokens[1].kind == TkIdentifier
    check tokens[1].value == "user"
    check tokens[2].kind == TkDot
    check tokens[3].kind == TkIdentifier
    check tokens[3].value == "age"
    check tokens[4].kind == TkOperator
    check tokens[4].value == ">="
    check tokens[18].kind == TkString
    check tokens[18].value == "edit"
    check tokens[19].kind == TkRightParen

  test "Whitespace handling":
    let input = "  if  \t  x   ==  \n  y  "
    let tokens = lexTagSection(input)
    check tokens.len == 4
    check tokens[0].kind == TkKeyword
    check tokens[1].kind == TkIdentifier
    check tokens[2].kind == TkOperator
    check tokens[3].kind == TkIdentifier

  test "Empty input":
    let input = ""
    let tokens = lexTagSection(input)
    check tokens.len == 0

  test "Unterminated string":
    expect LexerError:
      discard lexTagSection("'unterminated string")

  test "Unexpected character":
    expect LexerError:
      discard lexTagSection("valid_token @invalid_character")

  test "Nested structures":
    let input = "for product in collection limit: 5 offset: page_number | minus: 1 | times: 5"
    let tokens = lexTagSection(input)
    check tokens.len == 18
    check tokens[0].kind == TkKeyword
    check tokens[0].value == "for"
    check tokens[1].kind == TkIdentifier
    check tokens[1].value == "product"
    check tokens[2].kind == TkKeyword
    check tokens[2].value == "in"
    check tokens[4].kind == TkParameter
    check tokens[4].value == "limit"
    check tokens[5].kind == TkColon
    check tokens[10].kind == TkPipe

  test "Liquid specific constructs":
    let input = "assign x = 5 | plus: y | times: 2"
    let tokens = lexTagSection(input)
    check tokens.len == 12
    check tokens[0].kind == TkKeyword
    check tokens[0].value == "assign"
    check tokens[2].kind == TkAssign
    check tokens[4].kind == TkPipe
    check tokens[5].kind == TkIdentifier
    check tokens[5].value == "plus"

