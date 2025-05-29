import ../src/liquid/lexer/tags

suite "Liquid Template Parser Tests":
  test "Output section - simple variable":
    let tokens = @[Token(kind: TkIdentifier, value: "product"), Token(kind: TkDot, value: "."), Token(kind: TkIdentifier, value: "title")]
    let section = Section(sectionType: Output, tokens: tokens)
    let node = parseSection(section)
    check:
      node.kind == nkOutput
      node.children.len == 1
      node.children[0].kind == nkVariable
      node.children[0].segments.len == 2
      node.children[0].segments[0].kind == nkString
      node.children[0].segments[0].strVal == "product"
      node.children[0].segments[1].kind == nkString
      node.children[0].segments[1].strVal == "title"

  test "Output section - array variable":
    let tokens = @[Token(kind: TkIdentifier, value: "products"), Token(kind: TkLeftBracket, value: "["), Token(kind: TkNumber, value: "0"), Token(kind: TkRightBracket, value: "]")]
    let section = Section(sectionType: Output, tokens: tokens)
    let node = parseSection(section)
    check:
      node.kind == nkOutput
      node.children.len == 1
      node.children[0].kind == nkVariable
      node.children[0].segments.len == 2
      node.children[0].segments[0].kind == nkString
      node.children[0].segments[0].strVal == "products"
      node.children[0].segments[1].kind == nkNumber
      node.children[0].segments[1].numVal == 0.0

  test "Output section - complex variable":
    let tokens = @[Token(kind: TkIdentifier, value: "products"), Token(kind: TkDot, value: "."), Token(kind: TkIdentifier, value: "list_by_producer"), Token(kind: TkLeftBracket, value: "["), Token(kind: TkNumber, value: "0"), Token(kind: TkRightBracket, value: "]"), Token(kind: TkLeftBracket, value: "["), Token(kind: TkNumber, value: "0"), Token(kind: TkRightBracket, value: "]"), Token(kind: TkDot, value: "."), Token(kind: TkIdentifier, value: "price")]
    let section = Section(sectionType: Output, tokens: tokens)
    let node = parseSection(section)

    check:
      node.kind == nkOutput
      node.children.len == 1
      node.children[0].kind == nkVariable
      node.children[0].segments.len == 5

      node.children[0].segments[0].kind == nkString
      node.children[0].segments[0].strVal == "products"

      node.children[0].segments[1].kind == nkString
      node.children[0].segments[1].strVal == "list_by_producer"

      node.children[0].segments[2].kind == nkNumber
      node.children[0].segments[2].numVal == 0.0

      node.children[0].segments[3].kind == nkNumber
      node.children[0].segments[3].numVal == 0.0

      node.children[0].segments[4].kind == nkString
      node.children[0].segments[4].strVal == "price"


      #node.children[0].name == "products.list_by_producer[0][0].price"

  test "Output section - variable with filter":
    let tokens = @[
      Token(kind: TkIdentifier, value: "product"),
      Token(kind: TkDot, value: "."),
      Token(kind: TkIdentifier, value: "title"),
      Token(kind: TkPipe, value: "|"),
      Token(kind: TkIdentifier, value: "upcase")
    ]
    let section = Section(sectionType: Output, tokens: tokens)
    let node = parseSection(section)
    check:
      node.kind == nkOutput
      node.children.len == 1
      node.children[0].kind == nkFilter
      node.children[0].filterName == "upcase"
      node.children[0].arguments.len == 1
      node.children[0].arguments[0].kind == nkVariable
      node.children[0].arguments[0].segments.len == 2

  test "If tag - simple condition":
    let tokens = @[
      Token(kind: TkKeyword, value: "if"),
      Token(kind: TkIdentifier, value: "user"),
      Token(kind: TkDot, value: "."),
      Token(kind: TkIdentifier, value: "age"),
      Token(kind: TkOperator, value: ">="),
      Token(kind: TkNumber, value: "18")
    ]
    let section = Section(sectionType: Tag, tokens: tokens)
    let node = parseSection(section)
    check:
      node.kind == nkIf
      node.condition.kind == nkComparison
      node.condition.op == ">="
      node.condition.left.kind == nkVariable
      node.condition.left.segments.len == 2
      node.condition.right.kind == nkNumber
      node.condition.right.numVal == 18.0

  test "For tag - basic loop":
    let tokens = @[
      Token(kind: TkKeyword, value: "for"),
      Token(kind: TkIdentifier, value: "product"),
      Token(kind: TkOperator, value: "in"),
      Token(kind: TkIdentifier, value: "collection"),
      Token(kind: TkDot, value: "."),
      Token(kind: TkIdentifier, value: "products")
    ]
    let section = Section(sectionType: Tag, tokens: tokens)
    let node = parseSection(section)
    check:
      node.kind == nkFor
      node.iterVar == "product"
      node.collection.kind == nkVariable
      node.collection.segments.len == 2
      node.parameters.len == 0

  test "For tag - with parameters":
    let tokens = @[
      Token(kind: TkKeyword, value: "for"),
      Token(kind: TkIdentifier, value: "product"),
      Token(kind: TkOperator, value: "in"),
      Token(kind: TkIdentifier, value: "collection"),
      Token(kind: TkDot, value: "."),
      Token(kind: TkIdentifier, value: "products"),
      Token(kind: TkParameter, value: "limit"),
      Token(kind: TkColon, value: ":"),
      Token(kind: TkNumber, value: "5"),
      Token(kind: TkParameter, value: "offset"),
      Token(kind: TkColon, value: ":"),
      Token(kind: TkNumber, value: "10")
    ]
    let section = Section(sectionType: Tag, tokens: tokens)
    let node = parseSection(section)
    check:
      node.kind == nkFor
      node.iterVar == "product"
      node.collection.kind == nkVariable
      node.collection.segments.len == 2
      node.parameters.len == 2
      node.parameters[0].kind == nkArgument
      node.parameters[0].argName == "limit"
      node.parameters[0].argValue.kind == nkNumber
      node.parameters[0].argValue.numVal == 5.0
      node.parameters[1].kind == nkArgument
      node.parameters[1].argName == "offset"
      node.parameters[1].argValue.kind == nkNumber
      node.parameters[1].argValue.numVal == 10.0

  test "Assign tag":
    let tokens = @[
      Token(kind: TkKeyword, value: "assign"),
      Token(kind: TkIdentifier, value: "my_variable"),
      Token(kind: TkAssign, value: "="),
      Token(kind: TkString, value: "Hello, World!")
    ]
    let section = Section(sectionType: Tag, tokens: tokens)
    let node = parseSection(section)
    check:
      node.kind == nkAssign
      node.variable == "my_variable"
      node.value.kind == nkString
      node.value.strVal == "Hello, World!"

  test "Capture tag":
    let tokens = @[
      Token(kind: TkKeyword, value: "capture"),
      Token(kind: TkIdentifier, value: "my_capture")
    ]
    let section = Section(sectionType: Tag, tokens: tokens)
    let node = parseSection(section)
    check:
      node.kind == nkCapture
      node.captureName == "my_capture"

  test "Cycle tag":
    let tokens = @[
      Token(kind: TkKeyword, value: "cycle"),
      Token(kind: TkString, value: "odd"),
      Token(kind: TkComma, value: ","),
      Token(kind: TkString, value: "even")
    ]
    let section = Section(sectionType: Tag, tokens: tokens)
    let node = parseSection(section)
    check:
      node.kind == nkCycle
      node.groupName == ""
      node.values.len == 2
      node.values[0].kind == nkString
      node.values[0].strVal == "odd"
      node.values[1].kind == nkString
      node.values[1].strVal == "even"

  test "Cycle tag with group name":
    let tokens = @[
      Token(kind: TkKeyword, value: "cycle"),
      Token(kind: TkIdentifier, value: "group1"),
      Token(kind: TkColon, value: ":"),
      Token(kind: TkString, value: "one"),
      Token(kind: TkComma, value: ","),
      Token(kind: TkString, value: "two"),
      Token(kind: TkComma, value: ","),
      Token(kind: TkString, value: "three")
    ]
    let section = Section(sectionType: Tag, tokens: tokens)
    let node = parseSection(section)
    check:
      node.kind == nkCycle
      node.groupName == "group1"
      node.values.len == 3
      node.values[0].kind == nkString
      node.values[0].strVal == "one"
      node.values[1].kind == nkString
      node.values[1].strVal == "two"
      node.values[2].kind == nkString
      node.values[2].strVal == "three"

  test "Complex expression with logical operators":
    let tokens = @[
      Token(kind: TkIdentifier, value: "product"),
      Token(kind: TkDot, value: "."),
      Token(kind: TkIdentifier, value: "price"),
      Token(kind: TkOperator, value: ">"),
      Token(kind: TkNumber, value: "10"),
      Token(kind: TkAnd, value: "and"),
      Token(kind: TkIdentifier, value: "product"),
      Token(kind: TkDot, value: "."),
      Token(kind: TkIdentifier, value: "available")
    ]
    let section = Section(sectionType: Output, tokens: tokens)
    let node = parseSection(section)
    check:
      node.kind == nkOutput
      node.children.len == 1
      node.children[0].kind == nkLogical
      node.children[0].op == "and"
      node.children[0].left.kind == nkComparison
      node.children[0].left.op == ">"
      node.children[0].right.kind == nkVariable
      node.children[0].right.segments.len == 2

  test "Array literal":
    let tokens = @[
      Token(kind: TkLeftBracket, value: "["),
      Token(kind: TkNumber, value: "1"),
      Token(kind: TkComma, value: ","),
      Token(kind: TkNumber, value: "2"),
      Token(kind: TkComma, value: ","),
      Token(kind: TkNumber, value: "3"),
      Token(kind: TkRightBracket, value: "]")
    ]
    let section = Section(sectionType: Output, tokens: tokens)
    let node = parseSection(section)
    check:
      node.kind == nkOutput
      node.children.len == 1
      node.children[0].kind == nkArray
      node.children[0].elements.len == 3
      node.children[0].elements[0].kind == nkNumber
      node.children[0].elements[0].numVal == 1.0
      node.children[0].elements[1].kind == nkNumber
      node.children[0].elements[1].numVal == 2.0
      node.children[0].elements[2].kind == nkNumber
      node.children[0].elements[2].numVal == 3.0

  test "Range expression":
    let tokens = @[
      Token(kind: TkLeftParen, value: "("),
      Token(kind: TkNumber, value: "1"),
      Token(kind: TkRange, value: ".."),
      Token(kind: TkNumber, value: "5"),
      Token(kind: TkRightParen, value: ")")
    ]
    let section = Section(sectionType: Output, tokens: tokens)
    let node = parseSection(section)
    check:
      node.kind == nkOutput
      node.children.len == 1
      node.children[0].kind == nkRange
      node.children[0].rangeStart.kind == nkNumber
      node.children[0].rangeStart.numVal == 1.0
      node.children[0].rangeEnd.kind == nkNumber
      node.children[0].rangeEnd.numVal == 5.0

  test "Filter with multiple arguments":
    let tokens = lexTagSection("products | sort: 'price', 'desc'")
    # let tokens = @[
    #   Token(kind: TkIdentifier, value: "products"),
    #   Token(kind: TkPipe, value: "|"),
    #   Token(kind: TkIdentifier, value: "sort"),
    #   Token(kind: TkColon, value: ":"),
    #   Token(kind: TkString, value: "price"),
    #   Token(kind: TkComma, value: ","),
    #   Token(kind: TkString, value: "desc")
    # ]
    let section = Section(sectionType: Output, tokens: tokens)
    let node = parseSection(section)
    check:
      node.kind == nkOutput
      node.children.len == 1
      node.children[0].kind == nkFilter
      node.children[0].filterName == "sort"
      node.children[0].arguments.len == 3
      node.children[0].arguments[1].kind == nkArgument
      node.children[0].arguments[1].argName == ""
      node.children[0].arguments[1].argValue.kind == nkString
      node.children[0].arguments[1].argValue.strVal == "price"
      node.children[0].arguments[2].kind == nkArgument
      node.children[0].arguments[2].argName == ""
      node.children[0].arguments[2].argValue.kind == nkString
      node.children[0].arguments[2].argValue.strVal == "desc"
