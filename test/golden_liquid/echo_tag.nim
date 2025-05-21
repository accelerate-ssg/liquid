import helpers

suite "echo tag":
  testCase(
    "access an array item by index",
    "{% echo product.tags[1] %}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "echo"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "tags"),
        token(TkLeftBracket),
        token(TkNumber, "1"),
        token(TkRightBracket)
      ],
      nodeEcho(
        nodeVariable("product.tags[1]")
      ))
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "garden"
  )

  testCase(
    "access an array item by negative index",
    "{% echo product.tags[-2] %}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "echo"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "tags"),
        token(TkLeftBracket),
        token(TkNumber, "-2"),
        token(TkRightBracket)
      ], nodeEcho(nodeVariable("product.tags[-2]")))
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "sports"
  )

  testCase(
    "access an undefined variable by index",
    "{% echo nosuchthing[0] %}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "echo"),
        token(TkIdentifier, "nosuchthing"),
        token(TkLeftBracket),
        token(TkNumber, "0"),
        token(TkRightBracket)
      ], nodeEcho(nodeVariable("nosuchthing[0]")))
    ],
    output = ""
  )

  testCase(
    "access array item by index stored in a local variable",
    "{% assign i = 1 %}{% echo product.tags[i] %}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "assign"),
        token(TkIdentifier, "i"),
        token(TkAssign),
        token(TkNumber, "1")
      ], nodeAssign("i", nodeNumber(1.0))),
      section(SectionType.Tag, @[
        token(TkKeyword, "echo"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "tags"),
        token(TkLeftBracket),
        token(TkIdentifier, "i"),
        token(TkRightBracket)
      ], nodeEcho(nodeVariable("product.tags[i]")))
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "garden"
  )

  testCase(
    "assign a variable the value of an existing variable",
    "{% capture some %}hello{% endcapture %}{% assign other = some %}{% assign some = 'foo' %}{% echo some %}-{% echo other %}",
    @[
      section(SectionType.Tag, @[token(TkKeyword, "capture"), token(TkIdentifier, "some")], nodeCapture("some")),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkKeyword, "endcapture")], nodeEndCapture()),
      section(SectionType.Tag, @[
        token(TkKeyword, "assign"),
        token(TkIdentifier, "other"),
        token(TkAssign),
        token(TkIdentifier, "some")
      ], nodeAssign("other", nodeVariable("some"))),
      section(SectionType.Tag, @[
        token(TkKeyword, "assign"),
        token(TkIdentifier, "some"),
        token(TkAssign),
        token(TkString, "foo")
      ], nodeAssign("some", nodeString("foo"))),
      section(SectionType.Tag, @[token(TkKeyword, "echo"), token(TkIdentifier, "some")], nodeEcho(nodeVariable("some"))),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkKeyword, "echo"), token(TkIdentifier, "other")], nodeEcho(nodeVariable("other")))
    ],
    output = "foo-hello"
  )

  testCase(
    "dump an array from the global context",
    "{% echo product.tags %}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "echo"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "tags")
      ], nodeEcho(nodeVariable("product.tags")))
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "sportsgarden"
  )

  testCase(
    "nothing to echo",
    "{% echo %}",
    @[
      section(SectionType.Tag, @[token(TkKeyword, "echo")], nodeEcho(nodeNil()))
    ],
    output = ""
  )

  testCase(
    "render a float literal",
    "{% echo 1.23 %}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "echo"),
        token(TkNumber, "1.23")
      ], nodeEcho(nodeNumber(1.23)))
    ],
    output = "1.23"
  )

  testCase(
    "render a global identifier with a filter",
    "{% echo product.title | upcase %}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "echo"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "title"),
        token(TkPipe),
        token(TkIdentifier, "upcase")
      ], nodeEcho(nodeFilter("upcase", @[nodeVariable("product.title")])))
    ],
    context = %*{"product": {"title": "foo"}},
    output = "FOO"
  )

  testCase(
    "render a string literal",
    "{% echo 'hello' %}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "echo"),
        token(TkString, "hello")
      ], nodeEcho(nodeString("hello")))
    ],
    output = "hello"
  )

  testCase(
    "render a variable from the global namespace",
    "{% echo product.title %}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "echo"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "title")
      ], nodeEcho(nodeVariable("product.title")))
    ],
    context = %*{"product": {"title": "foo"}},
    output = "foo"
  )

  testCase(
    "render a variable from the local namespace",
    "{% assign name = 'Brian' %}{% echo name %}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "assign"),
        token(TkIdentifier, "name"),
        token(TkAssign),
        token(TkString, "Brian")
      ], nodeAssign("name", nodeString("Brian"))),
      section(SectionType.Tag, @[
        token(TkKeyword, "echo"),
        token(TkIdentifier, "name")
      ], nodeEcho(nodeVariable("name")))
    ],
    output = "Brian"
  )

  testCase(
    "render an integer literal",
    "{% echo 123 %}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "echo"),
        token(TkNumber, "123")
      ], nodeEcho(nodeNumber(123)))
    ],
    output = "123"
  )

  testCase(
    "render an undefined property",
    "{% echo product.age %}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "echo"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "age")
      ], nodeEcho(nodeVariable("product.age")))
    ],
    context = %*{"product": {"title": "foo"}},
    output = ""
  )

  testCase(
    "render an undefined variable",
    "{% echo age %}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "echo"),
        token(TkIdentifier, "age")
      ], nodeEcho(nodeVariable("age")))
    ],
    output = ""
  )

  testCase(
    "traverse variables with bracketed identifiers",
    "{% echo site.data.menu[include.menu][include.locale] %}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "echo"),
        token(TkIdentifier, "site"),
        token(TkDot),
        token(TkIdentifier, "data"),
        token(TkDot),
        token(TkIdentifier, "menu"),
        token(TkLeftBracket),
        token(TkIdentifier, "include"),
        token(TkDot),
        token(TkIdentifier, "menu"),
        token(TkRightBracket),
        token(TkLeftBracket),
        token(TkIdentifier, "include"),
        token(TkDot),
        token(TkIdentifier, "locale"),
        token(TkRightBracket)
      ], nodeEcho(nodeVariable("site.data.menu[include.menu][include.locale]")))
    ],
    context = %*{
      "site": {
        "data": {
          "menu": {
            "foo": {
              "bar": "it works!"
            }
          }
        }
      },
      "include": {
        "menu": "foo",
        "locale": "bar"
      }
    },
    output = "it works!"
  )
