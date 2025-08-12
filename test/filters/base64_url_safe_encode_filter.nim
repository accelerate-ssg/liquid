import helpers

suite "base64_url_safe_encode filter":
  testCase(
    "from string",
    "{{ \"_#/.\" | base64_url_safe_encode }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkString, "_#/."),
          token(TkPipe),
          token(TkIdentifier, "base64_url_safe_encode")
        ],
        nodeOutput(@[
          nodeFilter("base64_url_safe_encode", @[
            nodeString("_#/.")
          ])
        ])
      )
    ]
  )

  testCase(
    "from string with URL unsafe",
    "{{ a | base64_url_safe_encode }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "a"),
          token(TkPipe),
          token(TkIdentifier, "base64_url_safe_encode")
        ],
        nodeOutput(@[
          nodeFilter("base64_url_safe_encode", @[
            nodeVariable("a")
          ])
        ])
      )
    ],
    context = %*{"a": "abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ 1234567890 !@#$%^&*()-=_+/?.:;[]{}\\|"}
  )

  testCase(
    "not a string",
    "{{ 5 | base64_url_safe_encode }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkNumber, "5"),
          token(TkPipe),
          token(TkIdentifier, "base64_url_safe_encode")
        ],
        nodeOutput(@[
          nodeFilter("base64_url_safe_encode", @[
            nodeNumber(5)
          ])
        ])
      )
    ]
  )

  testCase(
    "undefined left value",
    "{{ nosuchthing | base64_url_safe_encode }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "nosuchthing"),
          token(TkPipe),
          token(TkIdentifier, "base64_url_safe_encode")
        ],
        nodeOutput(@[
          nodeFilter("base64_url_safe_encode", @[
            nodeVariable("nosuchthing")
          ])
        ])
      )
    ]
  )

  testCase(
    "unexpected argument",
    "{{ \"hello\" | base64_url_safe_encode: 5 }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkString, "hello"),
          token(TkPipe),
          token(TkIdentifier, "base64_url_safe_encode"),
          token(TkColon),
          token(TkNumber, "5")
        ],
        nodeOutput(@[
          nodeFilter(
            "base64_url_safe_encode",
            @[
              nodeString("hello"),
              nodeArgument("", 
                nodeNumber(5)
              )
            ]
          )
        ])
      )
    ],
    error = true
  )
