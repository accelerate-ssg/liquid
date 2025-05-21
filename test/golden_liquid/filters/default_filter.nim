import helpers

suite "default filter":
  testCase(
    "0.0 is not falsy",
    "{{ 0.0 | default: \"bar\" }}",
    @[
      section(SectionType.Output, @[
        token(TkNumber, "0.0"),
        token(TkPipe),
        token(TkIdentifier, "default"),
        token(TkColon),
        token(TkString, "bar")
      ], nodeOutput(@[
        nodeFilter("default", @[
          nodeNumber(0.0),
          nodeArgument("", nodeString("bar"))
        ])
      ]))
    ],
    output = "0.0"
  )

  testCase(
    "allow false",
    "{{ false | default: 'bar', allow_false:true }}",
    @[
      section(SectionType.Output, @[
        token(TkBoolean, "false"),
        token(TkPipe),
        token(TkIdentifier, "default"),
        token(TkColon),
        token(TkString, "bar"),
        token(TkComma),
        token(TkIdentifier, "allow_false"),
        token(TkColon),
        token(TkBoolean, "true")
      ], nodeOutput(@[
        nodeFilter("default", @[
          nodeBoolean(false),
          nodeArgument("", nodeString("bar")),
          nodeArgument("allow_false", nodeBoolean(true))
        ])
      ]))
    ],
    output = "false"
  )

  testCase(
    "allow false from context",
    "{{ false | default: 'bar', allow_false:foo }}",
    @[
      section(SectionType.Output, @[
        token(TkBoolean, "false"),
        token(TkPipe),
        token(TkIdentifier, "default"),
        token(TkColon),
        token(TkString, "bar"),
        token(TkComma),
        token(TkIdentifier, "allow_false"),
        token(TkColon),
        token(TkIdentifier, "foo")
      ], nodeOutput(@[
        nodeFilter("default", @[
          nodeBoolean(false),
          nodeArgument("", nodeString("bar")),
          nodeArgument("allow_false", nodeVariable("foo"))
        ])
      ]))
    ],
    context = %*{"foo": true},
    output = "false"
  )

  testCase(
    "empty",
    "{{ empty | default: bar }}",
    @[
      section(SectionType.Output, @[
        token(TkEmpty),
        token(TkPipe),
        token(TkIdentifier, "default"),
        token(TkColon),
        token(TkIdentifier, "bar")
      ], nodeOutput(@[
        nodeFilter("default", @[
          nodeEmpty(),
          nodeArgument("", nodeVariable("bar"))
        ])
      ]))
    ],
    output = ""
  )

  testCase(
    "empty array",
    "{{ a | default: 'foo' }}",
    @[
      section(SectionType.Output, @[
        token(TkIdentifier, "a"),
        token(TkPipe),
        token(TkIdentifier, "default"),
        token(TkColon),
        token(TkString, "foo")
      ], nodeOutput(@[
        nodeFilter("default", @[
          nodeVariable("a"),
          nodeArgument("", nodeString("foo"))
        ])
      ]))
    ],
    context = %*{"a": []},
    output = "foo"
  )

  testCase(
    "empty object",
    "{{ a | default: 'foo' }}",
    @[
      section(SectionType.Output, @[
        token(TkIdentifier, "a"),
        token(TkPipe),
        token(TkIdentifier, "default"),
        token(TkColon),
        token(TkString, "foo")
      ], nodeOutput(@[
        nodeFilter("default", @[
          nodeVariable("a"),
          nodeArgument("", nodeString("foo"))
        ])
      ]))
    ],
    context = %*{"a": %*{}},
    output = "foo"
  )

  testCase(
    "empty string",
    "{{ \"\" | default: \"foo\" }}",
    @[
      section(SectionType.Output, @[
        token(TkString, ""),
        token(TkPipe),
        token(TkIdentifier, "default"),
        token(TkColon),
        token(TkString, "foo")
      ], nodeOutput(@[
        nodeFilter("default", @[
          nodeString(""),
          nodeArgument("", nodeString("foo"))
        ])
      ]))
    ],
    output = "foo"
  )

  testCase(
    "false",
    "{{ false | default: 'foo' }}",
    @[
      section(SectionType.Output, @[
        token(TkBoolean, "false"),
        token(TkPipe),
        token(TkIdentifier, "default"),
        token(TkColon),
        token(TkString, "foo")
      ], nodeOutput(@[
        nodeFilter("default", @[
          nodeBoolean(false),
          nodeArgument("", nodeString("foo"))
        ])
      ]))
    ],
    output = "foo"
  )

  testCase(
    "false keyword argument before positional",
    "{{ false | default: allow_false: false, \"bar\" }}",
    @[
      section(SectionType.Output, @[
        token(TkBoolean, "false"),
        token(TkPipe),
        token(TkIdentifier, "default"),
        token(TkColon),
        token(TkIdentifier, "allow_false"),
        token(TkColon),
        token(TkBoolean, "false"),
        token(TkComma),
        token(TkString, "bar")
      ], nodeOutput(@[
        nodeFilter("default", @[
          nodeBoolean(false),
          nodeArgument("allow_false", nodeBoolean(false)),
          nodeArgument("", nodeString("bar"))
        ])
      ]))
    ],
    output = "bar"
  )

  testCase(
    "missing argument",
    "{{ false | default }}",
    @[
      section(SectionType.Output, @[
        token(TkBoolean, "false"),
        token(TkPipe),
        token(TkIdentifier, "default")
      ], nodeOutput(@[
        nodeFilter("default", @[
          nodeBoolean(false)
        ])
      ]))
    ],
    output = ""
  )

  testCase(
    "nil",
    "{{ nil | default: 'foo' }}",
    @[
      section(SectionType.Output, @[
        token(TkNil),
        token(TkPipe),
        token(TkIdentifier, "default"),
        token(TkColon),
        token(TkString, "foo")
      ], nodeOutput(@[
        nodeFilter("default", @[
          nodeNil(),
          nodeArgument("", nodeString("foo"))
        ])
      ]))
    ],
    output = "foo"
  )

  testCase(
    "not empty list",
    "{{ a | default: \"foo\" | join: \"#\" }}",
    @[
      section(SectionType.Output, @[
        token(TkIdentifier, "a"),
        token(TkPipe),
        token(TkIdentifier, "default"),
        token(TkColon),
        token(TkString, "foo"),
        token(TkPipe),
        token(TkIdentifier, "join"),
        token(TkColon),
        token(TkString, "#")
      ], nodeOutput(@[
        nodeFilter("join", @[
          nodeFilter("default", @[
            nodeVariable("a"),
            nodeArgument("", nodeString("foo"))
          ]),
          nodeArgument("", nodeString("#"))
        ])
      ]))
    ],
    context = %*{"a": ["hello", "world"]},
    output = "hello#world"
  )

  testCase(
    "not empty object",
    "{% assign b = a | default: foo %}{% for item in b %}({{ item[0] }},{{ item[1] }}){% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "assign"),
        token(TkIdentifier, "b"),
        token(TkAssign),
        token(TkIdentifier, "a"),
        token(TkPipe),
        token(TkIdentifier, "default"),
        token(TkColon),
        token(TkIdentifier, "foo")
      ],
        nodeAssign("b", nodeFilter("default", @[nodeVariable("a"), nodeArgument("", nodeVariable("foo"))]))),
      section(SectionType.Tag, @[
        token(TkKeyword, "for"),
        token(TkIdentifier, "item"),
        token(TkKeyword, "in"),
        token(TkIdentifier, "b")
      ], nodeFor("item", nodeVariable("b"), @[])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkIdentifier, "item"),
        token(TkLeftBracket),
        token(TkNumber, "0"),
        token(TkRightBracket),
      ], nodeOutput(@[
        nodeVariable("item[0]"),
      ])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkIdentifier, "item"),
        token(TkLeftBracket),
        token(TkNumber, "1"),
        token(TkRightBracket),
      ], nodeOutput(@[
        nodeVariable("item[1]"),
      ])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[
        token(TkKeyword, "endfor")
      ], nodeEndFor())
    ],
    context = %*{"a": {"greeting": "hello"}, "foo": {"greeting": "goodbye"}},
    output = "(greeting,hello)"
  )

  testCase(
    "not empty string",
    "{{ \"hello\" | default: \"foo\" }}",
    @[
      section(SectionType.Output, @[
        token(TkString, "hello"),
        token(TkPipe),
        token(TkIdentifier, "default"),
        token(TkColon),
        token(TkString, "foo")
      ], nodeOutput(@[
        nodeFilter("default", @[
          nodeString("hello"),
          nodeArgument("", nodeString("foo"))
        ])
      ]))
    ],
    output = "hello"
  )

  testCase(
    "too many arguments",
    "{{ None | default: 'foo', 'bar', 'baz' }}",
    @[
      section(SectionType.Output, @[
        token(TkIdentifier, "None"),
        token(TkPipe),
        token(TkIdentifier, "default"),
        token(TkColon),
        token(TkString, "foo"),
        token(TkComma),
        token(TkString, "bar"),
        token(TkComma),
        token(TkString, "baz")
      ], nodeOutput(@[
        nodeFilter("default", @[
          nodeVariable("None"),
          nodeArgument("", nodeString("foo")),
          nodeArgument("", nodeString("bar")),
          nodeArgument("", nodeString("baz"))
        ])
      ]))
    ],
    error = true
  )

  testCase(
    "true keyword argument before positional",
    "{{ false | default: allow_false: true, \"bar\" }}",
    @[
      section(SectionType.Output, @[
        token(TkBoolean, "false"),
        token(TkPipe),
        token(TkIdentifier, "default"),
        token(TkColon),
        token(TkIdentifier, "allow_false"),
        token(TkColon),
        token(TkBoolean, "true"),
        token(TkComma),
        token(TkString, "bar")
      ], nodeOutput(@[
        nodeFilter("default", @[
          nodeBoolean(false),
          nodeArgument("allow_false", nodeBoolean(true)),
          nodeArgument("", nodeString("bar"))
        ])
      ]))
    ],
    output = "false"
  )

  testCase(
    "undefined left value",
    "{{ nosuchthing | default: \"bar\" }}",
    @[
      section(SectionType.Output, @[
        token(TkIdentifier, "nosuchthing"),
        token(TkPipe),
        token(TkIdentifier, "default"),
        token(TkColon),
        token(TkString, "bar")
      ], nodeOutput(@[
        nodeFilter("default", @[
          nodeVariable("nosuchthing"),
          nodeArgument("", nodeString("bar"))
        ])
      ]))
    ],
    output = "bar"
  )

  testCase(
    "zero is not falsy",
    "{{ 0 | default: \"bar\" }}",
    @[
      section(SectionType.Output, @[
        token(TkNumber, "0"),
        token(TkPipe),
        token(TkIdentifier, "default"),
        token(TkColon),
        token(TkString, "bar")
      ], nodeOutput(@[
        nodeFilter("default", @[
          nodeNumber(0),
          nodeArgument("", nodeString("bar"))
        ])
      ]))
    ],
    output = "0"
  )

  testCase(
    "zero is not falsy with allow_false",
    "{{ 0 | default: \"bar\", allow_false: true }}",
    @[
      section(SectionType.Output, @[
        token(TkNumber, "0"),
        token(TkPipe),
        token(TkIdentifier, "default"),
        token(TkColon),
        token(TkString, "bar"),
        token(TkComma),
        token(TkIdentifier, "allow_false"),
        token(TkColon),
        token(TkBoolean, "true")
      ], nodeOutput(@[
        nodeFilter("default", @[
          nodeNumber(0),
          nodeArgument("", nodeString("bar")),
          nodeArgument("allow_false", nodeBoolean(true))
        ])
      ]))
    ],
    output = "0"
  )
