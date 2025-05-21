import helpers

suite "append filter":
  testCase(
    "argument not a string",
    "{{ \"hello\" | append: 5 }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkString, "hello"),
          token(TkPipe),
          token(TkIdentifier, "append"),
          token(TkColon),
          token(TkNumber, "5")
        ],
        nodeOutput(@[
          nodeFilter("append", @[
            nodeString("hello"),
            nodeArgument("", nodeNumber(5))
          ])
        ])
      )
    ]
  )

  testCase(
    "concat",
    "{{ \"hello\" | append: \"there\" }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkString, "hello"),
          token(TkPipe),
          token(TkIdentifier, "append"),
          token(TkColon),
          token(TkString, "there")
        ],
        nodeOutput(@[
          nodeFilter("append", @[
            nodeString("hello"),
            nodeArgument("", nodeString("there"))
          ])
        ])
      )
    ]
  )

  testCase(
    "missing argument",
    "{{ \"hello\" | append }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkString, "hello"),
          token(TkPipe),
          token(TkIdentifier, "append")
        ],
        nodeOutput(@[
          nodeFilter("append", @[
            nodeString("hello")
          ])
        ])
      )
    ]
  )

  testCase(
    "not a string",
    "{{ 5 | append: 'there' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "5"),
          token(TkPipe),
          token(TkIdentifier, "append"),
          token(TkColon),
          token(TkString, "there")
        ],
        nodeOutput(@[
          nodeFilter("append", @[
            nodeNumber(5),
            nodeArgument("", nodeString("there"))
          ])
        ])
      )
    ]
  )

  testCase(
    "too many arguments",
    "{{ \"hello\" | append: \"how\", \"are\", \"you\" }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkString, "hello"),
          token(TkPipe),
          token(TkIdentifier, "append"),
          token(TkColon),
          token(TkString, "how"),
          token(TkComma),
          token(TkString, "are"),
          token(TkComma),
          token(TkString, "you")
        ],
        nodeOutput(@[
          nodeFilter("append", @[
            nodeString("hello"),
            nodeArgument("", nodeString("how")),
            nodeArgument("", nodeString("are")),
            nodeArgument("", nodeString("you"))
          ])
        ])
      )
    ]
  )

  testCase(
    "undefined argument",
    "{{ \"hi\" | append: nosuchthing }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkString, "hi"),
          token(TkPipe),
          token(TkIdentifier, "append"),
          token(TkColon),
          token(TkIdentifier, "nosuchthing")
        ],
        nodeOutput(@[
          nodeFilter("append", @[
            nodeString("hi"),
            nodeArgument("", nodeVariable("nosuchthing"))
          ])
        ])
      )
    ]
  )

  testCase(
    "undefined left value",
    "{{ nosuchthing | append: \"hi\" }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "nosuchthing"),
          token(TkPipe),
          token(TkIdentifier, "append"),
          token(TkColon),
          token(TkString, "hi")
        ],
        nodeOutput(@[
          nodeFilter("append", @[
            nodeVariable("nosuchthing"),
            nodeArgument("", nodeString("hi"))
          ])
        ])
      )
    ]
  )
