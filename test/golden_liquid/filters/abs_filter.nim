import helpers

suite "abs filter":
  testCase(
    "negative float",
    "{{ -5.4 | abs }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "-5.4"),
          token(TkPipe),
          token(TkIdentifier, "abs")
        ],
        nodeOutput(@[
          nodeFilter("abs", @[
            nodeNumber(-5.4)
          ])
        ])
      )
    ]
  )
 
  testCase(
    "negative integer",
    "{{ -5 | abs }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "-5"),
          token(TkPipe),
          token(TkIdentifier, "abs")
        ],
        nodeOutput(@[
          nodeFilter("abs", @[
            nodeNumber(-5)
          ])
        ])
      )
    ]
  )
 
  testCase(
    "negative string float",
    "{{ '-5.1' | abs }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkString, "-5.1"),
          token(TkPipe),
          token(TkIdentifier, "abs")
        ],
        nodeOutput(@[
          nodeFilter("abs", @[
            nodeString("-5.1")
          ])
        ])
      )
    ]
  )

  testCase(
    "negative string integer",
    "{{ \"-5\" | abs }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkString, "-5"),
          token(TkPipe),
          token(TkIdentifier, "abs")
        ],
        nodeOutput(@[
          nodeFilter("abs", @[
            nodeString("-5")
          ])
        ])
      )
    ]
  )

  testCase(
    "not a string, int or float",
    "{{ a | abs }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "a"),
          token(TkPipe),
          token(TkIdentifier, "abs")
        ],
        nodeOutput(@[
          nodeFilter("abs", @[
            nodeVariable("a")
          ])
        ])
      )
    ]
  )

  testCase(
    "positive float",
    "{{ 5.4 | abs }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "5.4"),
          token(TkPipe),
          token(TkIdentifier, "abs")
        ],
        nodeOutput(@[
          nodeFilter("abs", @[
            nodeNumber(5.4)
          ])
        ])
      )
    ]
  )
 
  testCase(
    "positive integer",
    "{{ 5 | abs }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "5"),
          token(TkPipe),
          token(TkIdentifier, "abs")
        ],
        nodeOutput(@[
          nodeFilter("abs", @[
            nodeNumber(5)
          ])
        ])
      )
    ]
  )

  testCase(
    "positive string float",
    "{{ '5.1' | abs }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkString, "5.1"),
          token(TkPipe),
          token(TkIdentifier, "abs")
        ],
        nodeOutput(@[
          nodeFilter("abs", @[
            nodeString("5.1")
          ])
        ])
      )
    ]
  )

  testCase(
    "positive string integer",
    "{{ \"5\" | abs }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkString, "5"),
          token(TkPipe),
          token(TkIdentifier, "abs")
        ],
        nodeOutput(@[
          nodeFilter("abs", @[
            nodeString("5")
          ])
        ])
      )
    ]
  )

  testCase(
    "string, not a number",
    "{{ 'hello' | abs }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkString, "hello"),
          token(TkPipe),
          token(TkIdentifier, "abs")
        ],
        nodeOutput(@[
          nodeFilter("abs", @[
            nodeString("hello")
          ])
        ])
      )
    ]
  )

  testCase(
    "undefined lhs",
    "{{ nosuchthing | abs }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "nosuchthing"),
          token(TkPipe),
          token(TkIdentifier, "abs")
        ],
        nodeOutput(@[
          nodeFilter("abs", @[
            nodeVariable("nosuchthing")
          ])
        ])
      )
    ]
  )

  testCase(
    "unexpected argument",
    "{{ -3 | abs: 1 }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "-3"),
          token(TkPipe),
          token(TkIdentifier, "abs"),
          token(TkColon),
          token(TkNumber, "1")
        ],
        nodeOutput(@[
          nodeFilter(
            "abs",
            @[
              nodeNumber(-3),
              nodeArgument("", 
                nodeNumber(1),
              )
            ]
          )
        ])
      )
    ]
  )

  testCase(
    "negative integer",
    "{{ 0 | abs }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "0"),
          token(TkPipe),
          token(TkIdentifier, "abs")
        ],
        nodeOutput(@[
          nodeFilter("abs", @[
            nodeNumber(0)
          ])
        ])
      )
    ]
  )
  