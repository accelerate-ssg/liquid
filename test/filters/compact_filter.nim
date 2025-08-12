import helpers

suite "compact filter":
  testCase(
    "array of objects with key property",
    "{% assign x = a | compact: 'title' %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "assign"),
          token(TkIdentifier, "x"),
          token(TkAssign),
          token(TkIdentifier, "a"),
          token(TkPipe),
          token(TkIdentifier, "compact"),
          token(TkColon),
          token(TkString, "title")
        ],
        nodeAssign("x", nodeFilter("compact", @[nodeVariable("a"), nodeArgument("", nodeString("title"))]))),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "for"),
          token(TkIdentifier, "obj"),
          token(TkOperator, "in"),
          token(TkIdentifier, "x")
        ],
        nodeFor("obj", nodeVariable("x"), @[])),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "for"),
          token(TkIdentifier, "i"),
          token(TkOperator, "in"),
          token(TkIdentifier, "obj")
        ],
        nodeFor("i", nodeVariable("obj"), @[])),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "i"),
          token(TkLeftBracket),
          token(TkNumber, "0"),
          token(TkRightBracket)
        ],
        nodeOutput(@[
          nodeVariable("i[0]"),
        ])),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "i"),
          token(TkLeftBracket),
          token(TkNumber, "1"),
          token(TkRightBracket)
        ],
        nodeOutput(@[
          nodeVariable("i[1]"),
        ])),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "endfor")],
        nodeEndFor()),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "endfor")],
        nodeEndFor())
    ],
    context = %*{
      "a": [
        {"title": "foo", "name": "a"},
        {"title": nil, "name": "b"},
        {"title": "bar", "name": "c"}
      ]
    },
    output = "(title,foo)(name,a)(title,bar)(name,c)"
  )

  testCase(
    "array with a nil",
    "{{ a | compact | join: '#' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "a"),
          token(TkPipe),
          token(TkIdentifier, "compact"),
          token(TkPipe),
          token(TkIdentifier, "join"),
          token(TkColon),
          token(TkString, "#")
        ],
        nodeOutput(@[
          nodeFilter(
            "join",
            @[
              nodeFilter("compact", @[nodeVariable("a")]),
              nodeArgument("", nodeString("#"))
            ]
          )
        ])
      )
    ],
    context = %*{"a": ["b", "a", nil, "A"]},
    output = "b#a#A"
  )

  testCase(
    "empty array",
    "{{ a | compact | join: '#' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "a"),
          token(TkPipe),
          token(TkIdentifier, "compact"),
          token(TkPipe),
          token(TkIdentifier, "join"),
          token(TkColon),
          token(TkString, "#")
        ],
        nodeOutput(@[
          nodeFilter(
            "join",
            @[
              nodeFilter("compact", @[nodeVariable("a")]),
              nodeArgument("", nodeString("#"))
            ]
          )
        ])
      )
    ],
    context = %*{"a": []},
    output = ""
  )

  testCase(
    "left value is not an array",
    "{{ a | compact | first }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "a"),
          token(TkPipe),
          token(TkIdentifier, "compact"),
          token(TkPipe),
          token(TkIdentifier, "first")
        ],
        nodeOutput(@[
          nodeFilter(
            "first",
            @[nodeFilter("compact", @[nodeVariable("a")])]
          )
        ])
      )
    ],
    context = %*{"a": 123},
    output = "123"
  )

  testCase(
    "left value is undefined",
    "{{ nosuchthing | compact }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "nosuchthing"),
          token(TkPipe),
          token(TkIdentifier, "compact")
        ],
        nodeOutput(@[
          nodeFilter("compact", @[nodeVariable("nosuchthing")])
        ])
      )
    ],
    output = ""
  )

  testCase(
    "too many arguments",
    "{{ a | compact: 'foo', 'bar' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "a"),
          token(TkPipe),
          token(TkIdentifier, "compact"),
          token(TkColon),
          token(TkString, "foo"),
          token(TkComma),
          token(TkString, "bar")
        ],
        nodeOutput(@[
          nodeFilter(
            "compact",
            @[
              nodeVariable("a"),
              nodeArgument("", nodeString("foo")),
              nodeArgument("", nodeString("bar"))
            ]
          )
        ])
      )
    ],
    error = true
  )
