suite "Liquid Output Section Lexer Tests":

  test "Basic variable":
    let input = "user.name"
    let tokens = lexTagSection(input)
    check:
      tokens.len == 3
      tokens[0].kind == TkIdentifier and tokens[0].value == "user"
      tokens[1].kind == TkDot
      tokens[2].kind == TkIdentifier and tokens[2].value == "name"

  test "Variable with filter":
    let input = "product.title | upcase"
    let tokens = lexTagSection(input)
    check:
      tokens.len == 5
      tokens[0].kind == TkIdentifier and tokens[0].value == "product"
      tokens[1].kind == TkDot
      tokens[2].kind == TkIdentifier and tokens[2].value == "title"
      tokens[3].kind == TkPipe
      tokens[4].kind == TkIdentifier and tokens[4].value == "upcase"

  test "Multiple filters":
    let input = "product.price | round: 2 | prepend: '$'"
    let tokens = lexTagSection(input)
    check:
      tokens.len == 11
      tokens[3].kind == TkPipe
      tokens[4].kind == TkIdentifier and tokens[4].value == "round"
      tokens[5].kind == TkColon
      tokens[6].kind == TkNumber and tokens[6].value == "2"
      tokens[7].kind == TkPipe
      tokens[8].kind == TkIdentifier and tokens[8].value == "prepend"
      tokens[9].kind == TkColon
      tokens[10].kind == TkString and tokens[10].value == "$"

  test "Filter with multiple arguments":
    let input = "collection.products | sort: 'price', 'desc'"
    let tokens = lexTagSection(input)
    check:
      tokens.len == 9
      tokens[4].kind == TkIdentifier and tokens[4].value == "sort"
      tokens[5].kind == TkColon
      tokens[6].kind == TkString and tokens[6].value == "price"
      tokens[7].kind == TkComma
      tokens[8].kind == TkString and tokens[8].value == "desc"

  test "Numeric literals":
    let input = "42 3.14 -10"
    let tokens = lexTagSection(input)
    check:
      tokens.len == 4
      tokens[0].kind == TkNumber and tokens[0].value == "42"
      tokens[1].kind == TkNumber and tokens[1].value == "3.14"
      tokens[2].kind == TkOperator and tokens[2].value == "-"
      tokens[3].kind == TkNumber and tokens[3].value == "10"

  test "String literals":
    let input = "'single quoted' \"double quoted\""
    let tokens = lexTagSection(input)
    check:
      tokens.len == 2
      tokens[0].kind == TkString and tokens[0].value == "single quoted"
      tokens[1].kind == TkString and tokens[1].value == "double quoted"

  test "Operators":
    let input = "x == y != z > w >= v < u <= t"
    let tokens = lexTagSection(input)
    check:
      tokens.len == 13
      tokens[1].kind == TkOperator and tokens[1].value == "=="
      tokens[3].kind == TkOperator and tokens[3].value == "!="
      tokens[5].kind == TkOperator and tokens[5].value == ">"
      tokens[7].kind == TkOperator and tokens[7].value == ">="
      tokens[9].kind == TkOperator and tokens[9].value == "<"
      tokens[11].kind == TkOperator and tokens[11].value == "<="

  test "Parentheses and brackets":
    let input = "array[0] (1 + 2)"
    let tokens = lexTagSection(input)
    check:
      tokens.len == 9
      tokens[1].kind == TkLeftBracket
      tokens[2].kind == TkNumber and tokens[2].value == "0"
      tokens[3].kind == TkRightBracket
      tokens[4].kind == TkLeftParen
      tokens[6].kind == TkOperator and tokens[6].value == "+"
      tokens[8].kind == TkRightParen

  test "Complex expression":
    let input = "user.orders | where: 'status', 'shipped' | map: 'total' | sum | round: 2"
    let tokens = lexTagSection(input)
    check:
      tokens.len == 19
      tokens[0].kind == TkIdentifier and tokens[0].value == "user"
      tokens[2].kind == TkIdentifier and tokens[2].value == "orders"
      tokens[3].kind == TkPipe
      tokens[4].kind == TkIdentifier and tokens[4].value == "where"
      tokens[9].kind == TkPipe
      tokens[10].kind == TkIdentifier and tokens[10].value == "map"
      tokens[13].kind == TkPipe
      tokens[14].kind == TkIdentifier and tokens[14].value == "sum"
      tokens[15].kind == TkPipe
      tokens[16].kind == TkIdentifier and tokens[16].value == "round"

  test "Empty input":
    let input = ""
    let tokens = lexTagSection(input)
    check tokens.len == 0

  test "Whitespace handling":
    let input = "  product.price   |   currency   "
    let tokens = lexTagSection(input)
    check:
      tokens.len == 5
      tokens[0].kind == TkIdentifier and tokens[0].value == "product"
      tokens[4].kind == TkIdentifier and tokens[4].value == "currency"

  test "Error: Unterminated string":
    expect LexerError:
      discard lexTagSection("'unterminated string")

  test "Error: Invalid character":
    expect LexerError:
      discard lexTagSection("valid_token @ invalid_character")
