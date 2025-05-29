suite "range objects":
  testCase(
    "end is less than start",
    "{{ (start..end) | join: '#' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkLeftParen),
          token(TkIdentifier, "start"),
          token(TkRange),
          token(TkIdentifier, "end"),
          token(TkRightParen),
          token(TkPipe),
          token(TkIdentifier, "join"),
          token(TkColon),
          token(TkString, "#")
        ],
        nodeOutput(@[
          nodeFilter(
            nodeRange(nodeIdentifier("start"), nodeIdentifier("end")),
            "join",
            @[nodeString("#")]
          )
        ])
      )
    ],
    context = %*{"start": 5, "end": 1},
    output = ""
  )

  testCase(
    "end is not a number",
    "{{ (start..end) | join: '#' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkLeftParen),
          token(TkIdentifier, "start"),
          token(TkRange),
          token(TkIdentifier, "end"),
          token(TkRightParen),
          token(TkPipe),
          token(TkIdentifier, "join"),
          token(TkColon),
          token(TkString, "#")
        ],
        nodeOutput(@[
          nodeFilter(
            nodeRange(nodeIdentifier("start"), nodeIdentifier("end")),
            "join",
            @[nodeString("#")]
          )
        ])
      )
    ],
    context = %*{"start": "1", "end": "foo"},
    output = ""
  )

  testCase(
    "start and end are negative",
    "{{ (start..end) | join: '#' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkLeftParen),
          token(TkIdentifier, "start"),
          token(TkRange),
          token(TkIdentifier, "end"),
          token(TkRightParen),
          token(TkPipe),
          token(TkIdentifier, "join"),
          token(TkColon),
          token(TkString, "#")
        ],
        nodeOutput(@[
          nodeFilter(
            nodeRange(nodeIdentifier("start"), nodeIdentifier("end")),
            "join",
            @[nodeString("#")]
          )
        ])
      )
    ],
    context = %*{"start": -5, "end": -2},
    output = "-5#-4#-3#-2"
  )

  testCase(
    "start is negative",
    "{{ (start..end) | join: '#' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkLeftParen),
          token(TkIdentifier, "start"),
          token(TkRange),
          token(TkIdentifier, "end"),
          token(TkRightParen),
          token(TkPipe),
          token(TkIdentifier, "join"),
          token(TkColon),
          token(TkString, "#")
        ],
        nodeOutput(@[
          nodeFilter(
            nodeRange(nodeIdentifier("start"), nodeIdentifier("end")),
            "join",
            @[nodeString("#")]
          )
        ])
      )
    ],
    context = %*{"start": -5, "end": 1},
    output = "-5#-4#-3#-2#-1#0#1"
  )

  testCase(
    "start is not a number",
    "{{ (start..end) | join: '#' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkLeftParen),
          token(TkIdentifier, "start"),
          token(TkRange),
          token(TkIdentifier, "end"),
          token(TkRightParen),
          token(TkPipe),
          token(TkIdentifier, "join"),
          token(TkColon),
          token(TkString, "#")
        ],
        nodeOutput(@[
          nodeFilter(
            nodeRange(nodeIdentifier("start"), nodeIdentifier("end")),
            "join",
            @[nodeString("#")]
          )
        ])
      )
    ],
    context = %*{"start": "foo", "end": 5},
    output = "0#1#2#3#4#5"
  )