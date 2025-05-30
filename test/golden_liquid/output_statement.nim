suite "output statement":
  testCase(
    "access an array item by index",
    "{{ product.tags[1] }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "product"),
          token(TkDot),
          token(TkIdentifier, "tags"),
          token(TkLeftBracket),
          token(TkNumber, "1"),
          token(TkRightBracket)
        ],
        nodeOutput(@[
          nodeIndex(
            nodeDot(nodeIdentifier("product"), "tags"),
            nodeNumber(1)
          )
        ])
      )
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "garden"
  )

  testCase(
    "access an array item by negative index",
    "{{ product.tags[-2] }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "product"),
          token(TkDot),
          token(TkIdentifier, "tags"),
          token(TkLeftBracket),
          token(TkNumber, "-2"),
          token(TkRightBracket)
        ],
        nodeOutput(@[
          nodeIndex(
            nodeDot(nodeIdentifier("product"), "tags"),
            nodeNumber(-2)
          )
        ])
      )
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "sports"
  )

  testCase(
    "access an undefined variable by index",
    "{{ nosuchthing[0] }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "nosuchthing"),
          token(TkLeftBracket),
          token(TkNumber, "0"),
          token(TkRightBracket)
        ],
        nodeOutput(@[
          nodeIndex(
            nodeIdentifier("nosuchthing"),
            nodeNumber(0)
          )
        ])
      )
    ],
    output = ""
  )

  testCase(
    "access array item by index stored in a local variable",
    "{% assign i = 1 %}{{ product.tags[i] }}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "assign"),
          token(TkIdentifier, "i"),
          token(TkAssign),
          token(TkNumber, "1")
        ],
        nodeAssign("i", nodeNumber(1))
      ),
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "product"),
          token(TkDot),
          token(TkIdentifier, "tags"),
          token(TkLeftBracket),
          token(TkIdentifier, "i"),
          token(TkRightBracket)
        ],
        nodeOutput(@[
          nodeIndex(
            nodeDot(nodeIdentifier("product"), "tags"),
            nodeIdentifier("i")
          )
        ])
      )
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "garden"
  )

  testCase(
    "assign a variable the value of an existing variable",
    "{% capture some %}hello{% endcapture %}{% assign other = some %}{% assign some = 'foo' %}{{ some }}-{{ other }}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "capture"),
          token(TkIdentifier, "some")
        ],
        nodeCapture("some")
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "endcapture")
        ],
        nodeEndCapture()
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "assign"),
          token(TkIdentifier, "other"),
          token(TkAssign),
          token(TkIdentifier, "some")
        ],
        nodeAssign("other", nodeIdentifier("some"))
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "assign"),
          token(TkIdentifier, "some"),
          token(TkAssign),
          token(TkString, "foo")
        ],
        nodeAssign("some", nodeString("foo"))
      ),
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "some")
        ],
        nodeOutput(@[nodeIdentifier("some")])
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "other")
        ],
        nodeOutput(@[nodeIdentifier("other")])
      )
    ],
    output = "foo-hello"
  )

  testCase(
    "bracketed variable resolves to a string",
    "{{ foo[something] }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "foo"),
          token(TkLeftBracket),
          token(TkIdentifier, "something"),
          token(TkRightBracket)
        ],
        nodeOutput(@[
          nodeIndex(
            nodeIdentifier("foo"),
            nodeIdentifier("something")
          )
        ])
      )
    ],
    context = %*{"foo": {"hello": "goodbye"}, "something": "hello"},
    output = "goodbye"
  )

  testCase(
    "bracketed variable resolves to a string without leading identifier",
    "{{ [something] }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkLeftBracket),
          token(TkIdentifier, "something"),
          token(TkRightBracket)
        ],
        nodeOutput(@[
          nodeIndex(
            nodeNil(),
            nodeIdentifier("something")
          )
        ])
      )
    ],
    context = %*{"something": "hello", "hello": "goodbye"},
    output = "goodbye"
  )

  testCase(
    "chained bracketed identifier index",
    "{{ products[0].title }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "products"),
          token(TkLeftBracket),
          token(TkNumber, "0"),
          token(TkRightBracket),
          token(TkDot),
          token(TkIdentifier, "title")
        ],
        nodeOutput(@[
          nodeDot(
            nodeIndex(
              nodeIdentifier("products"),
              nodeNumber(0)
            ),
            "title"
          )
        ])
      )
    ],
    context = %*{"products": [{"title": "shoe"}, {"title": "hat"}]},
    output = "shoe"
  )

  testCase(
    "chained bracketed identifier index no dot",
    "{{ products[0]title }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "products"),
          token(TkLeftBracket),
          token(TkNumber, "0"),
          token(TkRightBracket),
          token(TkIdentifier, "title")
        ],
        nodeOutput(@[
          nodeDot(
            nodeIndex(
              nodeIdentifier("products"),
              nodeNumber(0)
            ),
            "title"
          )
        ])
      )
    ],
    context = %*{"products": [{"title": "shoe"}, {"title": "hat"}]},
    output = "shoe"
  )

  testCase(
    "chained identifier dot separated index",
    "{{ products.0.title }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "products"),
          token(TkDot),
          token(TkNumber, "0"),
          token(TkDot),
          token(TkIdentifier, "title")
        ],
        nodeOutput(@[
          nodeDot(
            nodeDot(nodeIdentifier("products"), "0"),
            "title"
          )
        ])
      )
    ],
    context = %*{"products": [{"title": "shoe"}, {"title": "hat"}]},
    error = true,
    strict = true
  )

  testCase(
    "dump an array from the global context",
    "{{ product.tags | join: '#' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "product"),
          token(TkDot),
          token(TkIdentifier, "tags"),
          token(TkPipe),
          token(TkIdentifier, "join"),
          token(TkColon),
          token(TkString, "#")
        ],
        nodeOutput(@[
          nodeFilter(
            nodeDot(nodeIdentifier("product"), "tags"),
            "join",
            @[nodeString("#")]
          )
        ])
      )
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "sports#garden"
  )

  testCase(
    "nested bracketed variable resolving to a string",
    "{{ [list[settings.zero]] }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkLeftBracket),
          token(TkIdentifier, "list"),
          token(TkLeftBracket),
          token(TkIdentifier, "settings"),
          token(TkDot),
          token(TkIdentifier, "zero"),
          token(TkRightBracket),
          token(TkRightBracket)
        ],
        nodeOutput(@[
          nodeIndex(
            nodeNil(),
            nodeIndex(
              nodeIdentifier("list"),
              nodeDot(nodeIdentifier("settings"), "zero")
            )
          )
        ])
      )
    ],
    context = %*{"list": ["foo"], "settings": {"zero": 0}, "foo": "bar"},
    output = "bar"
  )

  testCase(
    "quoted, bracketed variable name",
    "{{ foo['bar'] }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "foo"),
          token(TkLeftBracket),
          token(TkString, "bar"),
          token(TkRightBracket)
        ],
        nodeOutput(@[
          nodeIndex(
            nodeIdentifier("foo"),
            nodeString("bar")
          )
        ])
      )
    ],
    context = %*{"foo": {"bar": 42}},
    output = "42"
  )

  testCase(
    "quoted, bracketed variable name with whitespace",
    "{{ foo['bar baz'] }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "foo"),
          token(TkLeftBracket),
          token(TkString, "bar baz"),
          token(TkRightBracket)
        ],
        nodeOutput(@[
          nodeIndex(
            nodeIdentifier("foo"),
            nodeString("bar baz")
          )
        ])
      )
    ],
    context = %*{"foo": {"bar baz": 42}},
    output = "42"
  )

  testCase(
    "render a default given a literal false",
    "{{ false | default: 'bar' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkBoolean, "false"),
          token(TkPipe),
          token(TkIdentifier, "default"),
          token(TkColon),
          token(TkString, "bar")
        ],
        nodeOutput(@[
          nodeFilter(
            nodeBoolean(false),
            "default",
            @[nodeString("bar")]
          )
        ])
      )
    ],
    output = "bar"
  )

  testCase(
    "render a default given a literal false with 'allow false' equal to false",
    "{{ false | default: 'bar', allow_false: false }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkBoolean, "false"),
          token(TkPipe),
          token(TkIdentifier, "default"),
          token(TkColon),
          token(TkString, "bar"),
          token(TkComma),
          token(TkIdentifier, "allow_false"),
          token(TkColon),
          token(TkBoolean, "false")
        ],
        nodeOutput(@[
          nodeFilter(
            nodeBoolean(false),
            "default",
            @[
              nodeString("bar"),
              nodeArgument("allow_false", nodeBoolean(false))
            ]
          )
        ])
      )
    ],
    output = "bar"
  )

  testCase(
    "render a default given a literal false with 'allow false' equal to true",
    "{{ false | default: 'bar', allow_false: true }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkBoolean, "false"),
          token(TkPipe),
          token(TkIdentifier, "default"),
          token(TkColon),
          token(TkString, "bar"),
          token(TkComma),
          token(TkIdentifier, "allow_false"),
          token(TkColon),
          token(TkBoolean, "true")
        ],
        nodeOutput(@[
          nodeFilter(
            nodeBoolean(false),
            "default",
            @[
              nodeString("bar"),
              nodeArgument("allow_false", nodeBoolean(true))
            ]
          )
        ])
      )
    ],
    output = "false"
  )

  testCase(
    "render a float literal",
    "{{ 1.23 }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "1.23")
        ],
        nodeOutput(@[nodeNumber(1.23)])
      )
    ],
    output = "1.23"
  )

  testCase(
    "render a global variable with a filter",
    "{{ product.title | upcase }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "product"),
          token(TkDot),
          token(TkIdentifier, "title"),
          token(TkPipe),
          token(TkIdentifier, "upcase")
        ],
        nodeOutput(@[
          nodeFilter(
            nodeDot(nodeIdentifier("product"), "title"),
            "upcase",
            @[]
          )
        ])
      )
    ],
    context = %*{"product": {"title": "foo"}},
    output = "FOO"
  )

  testCase(
    "render a negative integer literal",
    "{{ -123 }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "-123")
        ],
        nodeOutput(@[nodeNumber(-123)])
      )
    ],
    output = "-123"
  )

  testCase(
    "render a range object",
    "{{ (1..5) | join: '#' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkLeftParen),
          token(TkNumber, "1"),
          token(TkRange),
          token(TkNumber, "5"),
          token(TkRightParen),
          token(TkPipe),
          token(TkIdentifier, "join"),
          token(TkColon),
          token(TkString, "#")
        ],
        nodeOutput(@[
          nodeFilter(
            nodeRange(nodeNumber(1), nodeNumber(5)),
            "join",
            @[nodeString("#")]
          )
        ])
      )
    ],
    output = "1#2#3#4#5"
  )

  testCase(
    "render a range object that uses a float",
    "{{ (1.4..5) | join: '#' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkLeftParen),
          token(TkNumber, "1.4"),
          token(TkRange),
          token(TkNumber, "5"),
          token(TkRightParen),
          token(TkPipe),
          token(TkIdentifier, "join"),
          token(TkColon),
          token(TkString, "#")
        ],
        nodeOutput(@[
          nodeFilter(
            nodeRange(nodeNumber(1.4), nodeNumber(5)),
            "join",
            @[nodeString("#")]
          )
        ])
      )
    ],
    output = "1#2#3#4#5"
  )

  testCase(
    "render a range object that uses an identifier",
    "{{ (foo..5) | join: '#' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkLeftParen),
          token(TkIdentifier, "foo"),
          token(TkRange),
          token(TkNumber, "5"),
          token(TkRightParen),
          token(TkPipe),
          token(TkIdentifier, "join"),
          token(TkColon),
          token(TkString, "#")
        ],
        nodeOutput(@[
          nodeFilter(
            nodeRange(nodeIdentifier("foo"), nodeNumber(5)),
            "join",
            @[nodeString("#")]
          )
        ])
      )
    ],
    context = %*{"foo": 2},
    output = "2#3#4#5"
  )

  testCase(
    "render a string literal",
    "{{ 'hello' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkString, "hello")
        ],
        nodeOutput(@[nodeString("hello")])
      )
    ],
    output = "hello"
  )

  testCase(
    "render a variable from the global namespace",
    "{{ product.title }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "product"),
          token(TkDot),
          token(TkIdentifier, "title")
        ],
        nodeOutput(@[
          nodeDot(nodeIdentifier("product"), "title")
        ])
      )
    ],
    context = %*{"product": {"title": "foo"}},
    output = "foo"
  )

  testCase(
    "render a variable from the local namespace",
    "{% assign name = 'Brian' %}{{ name }}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "assign"),
          token(TkIdentifier, "name"),
          token(TkAssign),
          token(TkString, "Brian")
        ],
        nodeAssign("name", nodeString("Brian"))
      ),
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "name")
        ],
        nodeOutput(@[nodeIdentifier("name")])
      )
    ],
    output = "Brian"
  )

  testCase(
    "render an integer literal",
    "{{ 123 }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "123")
        ],
        nodeOutput(@[nodeNumber(123)])
      )
    ],
    output = "123"
  )

  testCase(
    "render an output start sequence as a string literal",
    "{{ '{{' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkString, "{{")
        ],
        nodeOutput(@[nodeString("{{")])
      )
    ],
    output = "{{"
  )

  testCase(
    "render an undefined property",
    "{{ product.age }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "product"),
          token(TkDot),
          token(TkIdentifier, "age")
        ],
        nodeOutput(@[
          nodeDot(nodeIdentifier("product"), "age")
        ])
      )
    ],
    context = %*{"product": {"title": "foo"}},
    output = ""
  )

  testCase(
    "render an undefined variable",
    "{{ age }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "age")
        ],
        nodeOutput(@[nodeIdentifier("age")])
      )
    ],
    output = ""
  )

  testCase(
    "render nil",
    "{{ nil }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNil)
        ],
        nodeOutput(@[nodeNil()])
      )
    ],
    output = ""
  )

  testCase(
    "reverse a range",
    "{{ (foo..5) | reverse | join: '#' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkLeftParen),
          token(TkIdentifier, "foo"),
          token(TkRange),
          token(TkNumber, "5"),
          token(TkRightParen),
          token(TkPipe),
          token(TkIdentifier, "reverse"),
          token(TkPipe),
          token(TkIdentifier, "join"),
          token(TkColon),
          token(TkString, "#")
        ],
        nodeOutput(@[
          nodeFilter(
            nodeFilter(
              nodeRange(nodeIdentifier("foo"), nodeNumber(5)),
              "reverse",
              @[]
            ),
            "join",
            @[nodeString("#")]
          )
        ])
      )
    ],
    context = %*{"foo": 2},
    output = "5#4#3#2"
  )

  testCase(
    "top-level quoted, bracketed variable name with whitespace",
    "{{ ['bar baz'] }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkLeftBracket),
          token(TkString, "bar baz"),
          token(TkRightBracket)
        ],
        nodeOutput(@[
          nodeIndex(
            nodeNil(),
            nodeString("bar baz")
          )
        ])
      )
    ],
    context = %*{"bar baz": 42},
    output = "42"
  )

  testCase(
    "top-level quoted, bracketed variable name with whitespace followed by dot notation",
    "{{ ['bar baz'].qux }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkLeftBracket),
          token(TkString, "bar baz"),
          token(TkRightBracket),
          token(TkDot),
          token(TkIdentifier, "qux")
        ],
        nodeOutput(@[
          nodeDot(
            nodeIndex(
              nodeNil(),
              nodeString("bar baz")
            ),
            "qux"
          )
        ])
      )
    ],
    context = %*{"bar baz": {"qux": 42}},
    output = "42"
  )

  testCase(
    "traverse variables with bracketed identifiers",
    "{{ site.data.menu[include.menu][include.locale] }}",
    @[
      section(
        SectionType.Output,
        @[
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
        ],
        nodeOutput(@[
          nodeIndex(
            nodeIndex(
              nodeDot(nodeDot(nodeIdentifier("site"), "data"), "menu"),
              nodeDot(nodeIdentifier("include"), "menu")
            ),
            nodeDot(nodeIdentifier("include"), "locale")
          )
        ])
      )
    ],
    context = %*{
      "site": {"data": {"menu": {"foo": {"bar": "it works!"}}}},
      "include": {"menu": "foo", "locale": "bar"}
    },
    output = "it works!"
  )

  testCase(
    "unexpected left value for the `join` filter passes through",
    "{{ 12 | join: '#' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "12"),
          token(TkPipe),
          token(TkIdentifier, "join"),
          token(TkColon),
          token(TkString, "#")
        ],
        nodeOutput(@[
          nodeFilter(
            nodeNumber(12),
            "join",
            @[nodeString("#")]
          )
        ])
      )
    ],
    output = "12"
  )
