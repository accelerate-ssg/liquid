import helpers

suite "base64_url_safe_decode filter":
  testCase(
    "from string",
    "{{ \"XyMvLg==\" | base64_url_safe_decode }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkString, "XyMvLg=="),
          token(TkPipe),
          token(TkIdentifier, "base64_url_safe_decode")
        ],
        nodeOutput(@[
          nodeFilter("base64_url_safe_decode", @[
            nodeString("XyMvLg==")
          ])
        ])
      )
    ],
    output = "_#/."
  )

  testCase(
    "from string with URL unsafe",
    "{{ a | base64_url_safe_decode }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "a"),
          token(TkPipe),
          token(TkIdentifier, "base64_url_safe_decode")
        ],
        nodeOutput(@[
          nodeFilter("base64_url_safe_decode", @[
            nodeVariable("a")
          ])
        ])
      )
    ],
    context = %*{"a": "YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXogQUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVogMTIzNDU2Nzg5MCAhQCMkJV4mKigpLT1fKy8_Ljo7W117fVx8"},
    output = "abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ 1234567890 !@#$%^&*()-=_+/?.:;[]{}\\|"
  )

  testCase(
    "not a string",
    "{{ 5 | base64_url_safe_decode }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "5"),
          token(TkPipe),
          token(TkIdentifier, "base64_url_safe_decode")
        ],
        nodeOutput(@[
          nodeFilter("base64_url_safe_decode", @[
            nodeNumber(5)
          ])
        ])
      )
    ],
    error = true
  )

  testCase(
    "undefined left value",
    "{{ nosuchthing | base64_url_safe_decode }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "nosuchthing"),
          token(TkPipe),
          token(TkIdentifier, "base64_url_safe_decode")
        ],
        nodeOutput(@[
          nodeFilter("base64_url_safe_decode", @[
            nodeVariable("nosuchthing")
          ])
        ])
      )
    ]
  )

  testCase(
    "unexpected argument",
    "{{ \"hello\" | base64_url_safe_decode: 5 }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkString, "hello"),
          token(TkPipe),
          token(TkIdentifier, "base64_url_safe_decode"),
          token(TkColon),
          token(TkNumber, "5")
        ],
        nodeOutput(@[
          nodeFilter("base64_url_safe_decode", @[
            nodeString("hello"),
            nodeArgument("", nodeNumber(5))
          ])
        ])
      )
    ],
    error = true
  )
