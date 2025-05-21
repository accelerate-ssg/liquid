import helpers

suite "capitalize filter":
  testCase(
    "already capitalized string",
    "{{ \"Hello\" | capitalize }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkString, "Hello"),
          token(TkPipe),
          token(TkIdentifier, "capitalize")
        ],
        nodeOutput(@[
          nodeFilter("capitalize", @[
            nodeString("Hello")
          ])
        ])
      )
    ],
    output = "Hello"
  )

  testCase(
    "lower case string",
    "{{ \"hello\" | capitalize }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkString, "hello"),
          token(TkPipe),
          token(TkIdentifier, "capitalize")
        ],
        nodeOutput(@[
          nodeFilter("capitalize", @[
            nodeString("hello")
          ])
        ])
      )
    ],
    output = "Hello"
  )

  testCase(
    "undefined left value",
    "{{ nosuchthing | capitalize }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "nosuchthing"),
          token(TkPipe),
          token(TkIdentifier, "capitalize")
        ],
        nodeOutput(@[
          nodeFilter("capitalize", @[
            nodeVariable("nosuchthing")
          ])
        ])
      )
    ],
    output = ""
  )

  testCase(
    "unexpected argument",
    "{{ \"hello\" | capitalize: 2 }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkString, "hello"),
          token(TkPipe),
          token(TkIdentifier, "capitalize"),
          token(TkColon),
          token(TkNumber, "2")
        ],
        nodeOutput(@[
          nodeFilter(
            "capitalize",
            @[
              nodeString("hello"),
              nodeArgument("", 
                nodeNumber(2)
              )
            ]
          )
        ])
      )
    ],
    output = "",
    error = true
  )
