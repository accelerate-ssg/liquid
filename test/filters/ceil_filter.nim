import helpers

suite "ceil filter":
  testCase(
    "negative float",
    "{{ -5.4 | ceil }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "-5.4"),
          token(TkPipe),
          token(TkIdentifier, "ceil")
        ],
        nodeOutput(@[
          nodeFilter(
            "ceil",
            @[nodeNumber(-5.4)]
          )
        ])
      )
    ],
    output = "-5"
  )

  testCase(
    "negative integer",
    "{{ -5 | ceil }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "-5"),
          token(TkPipe),
          token(TkIdentifier, "ceil")
        ],
        nodeOutput(@[
          nodeFilter(
            "ceil",
            @[nodeNumber(-5)]
          )
        ])
      )
    ],
    output = "-5"
  )

  testCase(
    "negative string float",
    "{{ \"-5.1\" | ceil }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkString, "-5.1"),
          token(TkPipe),
          token(TkIdentifier, "ceil")
        ],
        nodeOutput(@[
          nodeFilter(
            "ceil",
            @[nodeString("-5.1")]
          )
        ])
      )
    ],
    output = "-5"
  )

  testCase(
    "not a string, int or float",
    "{{ a | ceil }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "a"),
          token(TkPipe),
          token(TkIdentifier, "ceil")
        ],
        nodeOutput(@[
          nodeFilter(
            "ceil",
            @[nodeVariable("a")]
          )
        ])
      )
    ],
    context = %*{"a": {}},
    output = "0"
  )

  testCase(
    "positive float",
    "{{ 5.4 | ceil }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "5.4"),
          token(TkPipe),
          token(TkIdentifier, "ceil")
        ],
        nodeOutput(@[
          nodeFilter(
            "ceil",
            @[nodeNumber(5.4)]
          )
        ])
      )
    ],
    output = "6"
  )

  testCase(
    "positive integer",
    "{{ 5 | ceil }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "5"),
          token(TkPipe),
          token(TkIdentifier, "ceil")
        ],
        nodeOutput(@[
          nodeFilter(
            "ceil",
            @[nodeNumber(5)]
          )
        ])
      )
    ],
    output = "5"
  )

  testCase(
    "positive string float",
    "{{ \"5.1\" | ceil }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkString, "5.1"),
          token(TkPipe),
          token(TkIdentifier, "ceil")
        ],
        nodeOutput(@[
          nodeFilter(
            "ceil",
            @[nodeString("5.1")]
          )
        ])
      )
    ],
    output = "6"
  )

  testCase(
    "string not a number",
    "{{ \"hello\" | ceil }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkString, "hello"),
          token(TkPipe),
          token(TkIdentifier, "ceil")
        ],
        nodeOutput(@[
          nodeFilter(
            "ceil",
            @[nodeString("hello")]
          )
        ])
      )
    ],
    output = "0"
  )

  testCase(
    "undefined left value",
    "{{ nosuchthing | ceil }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "nosuchthing"),
          token(TkPipe),
          token(TkIdentifier, "ceil")
        ],
        nodeOutput(@[
          nodeFilter(
            "ceil",
            @[nodeVariable("nosuchthing")]
          )
        ])
      )
    ],
    output = "0"
  )

  testCase(
    "unexpected argument",
    "{{ -3.1 | ceil: 1 }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "-3.1"),
          token(TkPipe),
          token(TkIdentifier, "ceil"),
          token(TkColon),
          token(TkNumber, "1")
        ],
        nodeOutput(@[
          nodeFilter(
            "ceil",
            @[
              nodeNumber(-3.1),
              nodeArgument("", nodeNumber(1))
            ]
          )
        ])
      )
    ],
    error = true
  )

  testCase(
    "zero",
    "{{ 0 | ceil }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "0"),
          token(TkPipe),
          token(TkIdentifier, "ceil")
        ],
        nodeOutput(@[
          nodeFilter(
            "ceil",
            @[nodeNumber(0)]
          )
        ])
      )
    ],
    output = "0"
  )
