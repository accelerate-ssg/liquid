import helpers

suite "base64_encode filter":
  testCase(
    "from string",
    "{{ \"_#/.\" | base64_encode }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkString, "_#/."),
          token(TkPipe),
          token(TkIdentifier, "base64_encode")
        ],
        nodeOutput(@[
          nodeFilter("base64_encode", @[
            nodeString("_#/.")
          ])
        ])
      )
    ],
    output = "XyMvLg=="
  )
