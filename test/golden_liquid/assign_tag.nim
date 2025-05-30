var testResults: seq[string]

suite "assign tag":
  testCase(
    "assign a filtered literal",
    "{% assign foo = 'foo' | upcase %}{{ foo }}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "assign"),
          token(TkIdentifier, "foo"),
          token(TkAssign),
          token(TkString, "foo"),
          token(TkPipe),
          token(TkIdentifier, "upcase")
        ],
        nodeAssign(
          "foo",
          nodeFilter("upcase", @[nodeString("foo")])
        )
      ),
      section(
        SectionType.Output,
        @[token(TkIdentifier, "foo")],
        nodeOutput(@[nodeVariable("foo")])
      )
    ],
    output = "FOO"
  )

  testCase(
    "assign a range literal",
    "{% assign foo = (1..3) %}{{ foo | join: '#' }}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "assign"),
          token(TkIdentifier, "foo"),
          token(TkAssign),
          token(TkLeftParen),
          token(TkNumber, "1"),
          token(TkRange),
          token(TkNumber, "3"),
          token(TkRightParen)
        ],
        nodeAssign(
          "foo",
          nodeRange(nodeNumber(1), nodeNumber(3))
        )
      ),
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "foo"),
          token(TkPipe),
          token(TkIdentifier, "join"),
          token(TkColon),
          token(TkString, "#")
        ],
        nodeOutput(@[
          nodeFilter("join", @[nodeVariable("foo"), nodeString("#")])
        ])
      )
    ],
    output = "1#2#3"
  )

  testCase(
    "assign an existing array",
    "{% assign foo = bar %}{{ foo[0] }}/{{ foo[1] }}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "assign"),
          token(TkIdentifier, "foo"),
          token(TkAssign),
          token(TkIdentifier, "bar")
        ],
        nodeAssign("foo", nodeVariable("bar"))
      ),
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "foo"),
          token(TkLeftBracket),
          token(TkNumber, "0"),
          token(TkRightBracket)
        ],
        nodeOutput(@[
          nodeVariable("foo[0]"),
        ])
      ),
      section(
        SectionType.Text,
        @[
        ],
        nil
      ),
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "foo"),
          token(TkLeftBracket),
          token(TkNumber, "1"),
          token(TkRightBracket)
        ],
        nodeOutput(@[
          nodeVariable("foo[1]"),
        ])
      )
    ],
    context = %*{"bar": ["a", "b", "c"]},
    output = "a/b"
  )

  testCase(
    "assign an item from an existing object with quoted notation",
    "{% assign foo = bar['baz'] %}{{ foo }}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "assign"),
          token(TkIdentifier, "foo"),
          token(TkAssign),
          token(TkIdentifier, "bar"),
          token(TkLeftBracket),
          token(TkString, "baz"),
          token(TkRightBracket)
        ],
        nodeAssign(
          "foo",
          nodeVariable("bar['baz']"),
        )
      ),
      section(
        SectionType.Output,
        @[token(TkIdentifier, "foo")],
        nodeOutput(@[nodeVariable("foo")])
      )
    ],
    context = %*{"bar": {"baz": "hello"}},
    output = "hello"
  )

  testCase(
    "assign to variable with a hyphen",
    "{% assign some-thing = 'foo' %}{{ some-thing }}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "assign"),
          token(TkIdentifier, "some-thing"),
          token(TkAssign),
          token(TkString, "foo")
        ],
        nodeAssign("some-thing", nodeString("foo"))
      ),
      section(
        SectionType.Output,
        @[token(TkIdentifier, "some-thing")],
        nodeOutput(@[nodeVariable("some-thing")])
      )
    ],
    output = "foo"
  )

  testCase(
    "assign with quoted notation and extra whitespace",
    "{% assign foo = bar[ 'baz'  ] %}{{ foo }}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "assign"),
          token(TkIdentifier, "foo"),
          token(TkAssign),
          token(TkIdentifier, "bar"),
          token(TkLeftBracket),
          token(TkString, "baz"),
          token(TkRightBracket)
        ],
        nodeAssign(
          "foo",
          nodeVariable("bar[baz]"),
        )
      ),
      section(
        SectionType.Output,
        @[token(TkIdentifier, "foo")],
        nodeOutput(@[nodeVariable("foo")])
      )
    ],
    context = %*{"bar": {"baz": "hello"}},
    output = "hello"
  )

  testCase(
    "local variables shadow global variables",
    "{{ foo }}{% assign foo = 'foo' | upcase %}{{ foo }}",
    @[
      section(
        SectionType.Output,
        @[token(TkIdentifier, "foo")],
        nodeOutput(@[nodeVariable("foo")])
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "assign"),
          token(TkIdentifier, "foo"),
          token(TkAssign),
          token(TkString, "foo"),
          token(TkPipe),
          token(TkIdentifier, "upcase")
        ],
        nodeAssign(
          "foo",
          nodeFilter("upcase", @[nodeString("foo")])
        )
      ),
      section(
        SectionType.Output,
        @[token(TkIdentifier, "foo")],
        nodeOutput(@[nodeVariable("foo")])
      )
    ],
    context = %*{"foo": "bar"},
    output = "barFOO"
  )