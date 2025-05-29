suite "special":
  testCase(
    "first of a string",
    "{{ s.first }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "s"),
          token(TkDot),
          token(TkIdentifier, "first")
        ],
        nodeOutput(@[
          nodeDot(nodeIdentifier("s"), "first")
        ])
      )
    ],
    context = %*{"s": "hello"},
    output = ""
  )

  testCase(
    "first of an array",
    "{{ a.first }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "a"),
          token(TkDot),
          token(TkIdentifier, "first")
        ],
        nodeOutput(@[
          nodeDot(nodeIdentifier("a"), "first")
        ])
      )
    ],
    context = %*{"a": [3, 2, 1]},
    output = "3"
  )

  testCase(
    "first of an empty object",
    "{{ obj.first | join: '#' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "obj"),
          token(TkDot),
          token(TkIdentifier, "first"),
          token(TkPipe),
          token(TkIdentifier, "join"),
          token(TkColon),
          token(TkString, "#")
        ],
        nodeOutput(@[
          nodeFilter(
            nodeDot(nodeIdentifier("obj"), "first"),
            "join",
            @[nodeString("#")]
          )
        ])
      )
    ],
    context = %*{"obj": {}},
    output = ""
  )

  testCase(
    "first of an object",
    "{{ obj.first | join: '#' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "obj"),
          token(TkDot),
          token(TkIdentifier, "first"),
          token(TkPipe),
          token(TkIdentifier, "join"),
          token(TkColon),
          token(TkString, "#")
        ],
        nodeOutput(@[
          nodeFilter(
            nodeDot(nodeIdentifier("obj"), "first"),
            "join",
            @[nodeString("#")]
          )
        ])
      )
    ],
    context = %*{"obj": {"a": 1, "b": 2}},
    output = "a#1"
  )

  testCase(
    "first of an object with a first property",
    "{{ obj.first }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "obj"),
          token(TkDot),
          token(TkIdentifier, "first")
        ],
        nodeOutput(@[
          nodeDot(nodeIdentifier("obj"), "first")
        ])
      )
    ],
    context = %*{"obj": {"a": 1, "first": 99}},
    output = "99"
  )

  testCase(
    "last of a object",
    "{{ obj.last }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "obj"),
          token(TkDot),
          token(TkIdentifier, "last")
        ],
        nodeOutput(@[
          nodeDot(nodeIdentifier("obj"), "last")
        ])
      )
    ],
    context = %*{"obj": {"a": 1, "b": 2}},
    output = ""
  )

  testCase(
    "last of a string",
    "{{ s.last }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "s"),
          token(TkDot),
          token(TkIdentifier, "last")
        ],
        nodeOutput(@[
          nodeDot(nodeIdentifier("s"), "last")
        ])
      )
    ],
    context = %*{"s": "hello"},
    output = ""
  )

  testCase(
    "last of an array",
    "{{ a.last }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "a"),
          token(TkDot),
          token(TkIdentifier, "last")
        ],
        nodeOutput(@[
          nodeDot(nodeIdentifier("a"), "last")
        ])
      )
    ],
    context = %*{"a": [3, 2, 1]},
    output = "1"
  )

  testCase(
    "last of an object with a last property",
    "{{ obj.last }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "obj"),
          token(TkDot),
          token(TkIdentifier, "last")
        ],
        nodeOutput(@[
          nodeDot(nodeIdentifier("obj"), "last")
        ])
      )
    ],
    context = %*{"obj": {"a": 1, "last": 99, "b": 42}},
    output = "99"
  )

  testCase(
    "size of a string",
    "{{ s.size }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "s"),
          token(TkDot),
          token(TkIdentifier, "size")
        ],
        nodeOutput(@[
          nodeDot(nodeIdentifier("s"), "size")
        ])
      )
    ],
    context = %*{"s": "hello"},
    output = "5"
  )

  testCase(
    "size of an array",
    "{{ a.size }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "a"),
          token(TkDot),
          token(TkIdentifier, "size")
        ],
        nodeOutput(@[
          nodeDot(nodeIdentifier("a"), "size")
        ])
      )
    ],
    context = %*{"a": [3, 2, 1]},
    output = "3"
  )

  testCase(
    "size of an object with a size property",
    "{{ obj.size }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "obj"),
          token(TkDot),
          token(TkIdentifier, "size")
        ],
        nodeOutput(@[
          nodeDot(nodeIdentifier("obj"), "size")
        ])
      )
    ],
    context = %*{"obj": {"size": 99}},
    output = "99"
  )

  testCase(
    "size of undefined",
    "{{ nosuchthing.last }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "nosuchthing"),
          token(TkDot),
          token(TkIdentifier, "last")
        ],
        nodeOutput(@[
          nodeDot(nodeIdentifier("nosuchthing"), "last")
        ])
      )
    ],
    output = ""
  )