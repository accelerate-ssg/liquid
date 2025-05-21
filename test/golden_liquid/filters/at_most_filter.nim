import helpers

suite "at_most filter":
  testCase(
    "left value not a number",
    "{{ \"abc\" | at_most: -2 }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkString, "abc"),
          token(TkPipe),
          token(TkIdentifier, "at_most"),
          token(TkColon),
          token(TkNumber, "-2")
        ],
        nodeOutput(@[
          nodeFilter("at_most", @[
            nodeString("abc"),
            nodeArgument("", nodeNumber(-2))
          ])
        ])
      )
    ]
  )

  testCase(
    "missing arg",
    "{{ 5 | at_most }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "5"),
          token(TkPipe),
          token(TkIdentifier, "at_most")
        ],
        nodeOutput(@[
          nodeFilter("at_most", @[
            nodeNumber(5)
          ])
        ])
      )
    ]
  )

  testCase(
    "negative integer < arg",
    "{{ -8 | at_most: 5 }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "-8"),
          token(TkPipe),
          token(TkIdentifier, "at_most"),
          token(TkColon),
          token(TkNumber, "5")
        ],
        nodeOutput(@[
          nodeFilter("at_most", @[
            nodeNumber(-8),
            nodeArgument("", nodeNumber(5))
          ])
        ])
      )
    ]
  )

  testCase(
    "positive float < arg",
    "{{ 5.4 | at_most: 8.9 }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "5.4"),
          token(TkPipe),
          token(TkIdentifier, "at_most"),
          token(TkColon),
          token(TkNumber, "8.9")
        ],
        nodeOutput(@[
          nodeFilter("at_most", @[
            nodeNumber(5.4),
            nodeArgument("", nodeNumber(8.9))
          ])
        ])
      )
    ]
  )

  testCase(
    "positive float > arg",
    "{{ 8.4 | at_most: 5.9 }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "8.4"),
          token(TkPipe),
          token(TkIdentifier, "at_most"),
          token(TkColon),
          token(TkNumber, "5.9")
        ],
        nodeOutput(@[
          nodeFilter("at_most", @[
            nodeNumber(8.4),
            nodeArgument("", nodeNumber(5.9))
          ])
        ])
      )
    ]
  )

  testCase(
    "positive integer < arg",
    "{{ 5 | at_most: 8 }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "5"),
          token(TkPipe),
          token(TkIdentifier, "at_most"),
          token(TkColon),
          token(TkNumber, "8")
        ],
        nodeOutput(@[
          nodeFilter("at_most", @[
            nodeNumber(5),
            nodeArgument("", nodeNumber(8))
          ])
        ])
      )
    ]
  )

  testCase(
    "positive integer == arg",
    "{{ 5 | at_most: 5 }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "5"),
          token(TkPipe),
          token(TkIdentifier, "at_most"),
          token(TkColon),
          token(TkNumber, "5")
        ],
        nodeOutput(@[
          nodeFilter("at_most", @[
            nodeNumber(5),
            nodeArgument("", nodeNumber(5))
          ])
        ])
      )
    ]
  )

  testCase(
    "positive integer > arg",
    "{{ 8 | at_most: 5 }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "8"),
          token(TkPipe),
          token(TkIdentifier, "at_most"),
          token(TkColon),
          token(TkNumber, "5")
        ],
        nodeOutput(@[
          nodeFilter("at_most", @[
            nodeNumber(8),
            nodeArgument("", nodeNumber(5))
          ])
        ])
      )
    ]
  )

  testCase(
    "positive string > arg",
    "{{ \"9\" | at_most: 8 }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkString, "9"),
          token(TkPipe),
          token(TkIdentifier, "at_most"),
          token(TkColon),
          token(TkNumber, "8")
        ],
        nodeOutput(@[
          nodeFilter("at_most", @[
            nodeString("9"),
            nodeArgument("", nodeNumber(8))
          ])
        ])
      )
    ]
  )

  testCase(
    "too many args",
    "{{ 5 | at_most: 1, 2}}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "5"),
          token(TkPipe),
          token(TkIdentifier, "at_most"),
          token(TkColon),
          token(TkNumber, "1"),
          token(TkComma),
          token(TkNumber, "2")
        ],
        nodeOutput(@[
          nodeFilter("at_most", @[
            nodeNumber(5),
            nodeArgument("", nodeNumber(1)),
            nodeArgument("", nodeNumber(2))
          ])
        ])
      )
    ]
  )

  testCase(
    "undefined argument",
    "{{ 5 | at_most: nosuchthing }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "5"),
          token(TkPipe),
          token(TkIdentifier, "at_most"),
          token(TkColon),
          token(TkIdentifier, "nosuchthing")
        ],
        nodeOutput(@[
          nodeFilter("at_most", @[
            nodeNumber(5),
            nodeArgument("", nodeVariable("nosuchthing"))
          ])
        ])
      )
    ]
  )

  testCase(
    "undefined left value",
    "{{ nosuchthing | at_most: 5 }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "nosuchthing"),
          token(TkPipe),
          token(TkIdentifier, "at_most"),
          token(TkColon),
          token(TkNumber, "5")
        ],
        nodeOutput(@[
          nodeFilter("at_most", @[
            nodeVariable("nosuchthing"),
            nodeArgument("", nodeNumber(5))
          ])
        ])
      )
    ]
  )
