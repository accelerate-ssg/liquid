
var testResults: seq[string]

suite "assign tag":
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
    context = %*{"bar": ["a", "b", "c"]}
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
    context = %*{"bar": {"baz": "hello"}}
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
    context = %*{"bar": {"baz": "hello"}}
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
    context = %*{"foo": "bar"}
  )
