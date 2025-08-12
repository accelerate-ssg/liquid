import helpers

suite "date filter":
  testCase(
    "literal percent",
    "{{ 'March 14, 2016' | date: '%%%b %d, %y' }}",
    @[
      
      section(SectionType.Output, @[
        token(TkString, "March 14, 2016"),
        token(TkPipe),
        token(TkIdentifier, "date"),
        token(TkColon),
        token(TkString, "%%%b %d, %y")
      ],
      nodeOutput(@[
        nodeFilter("date", @[nodeString("March 14, 2016"), nodeArgument("", nodeString("%%%b %d, %y"))])
      ]))
    ],
    output = "%Mar 14, 16"
  )

  testCase(
    "missing argument",
    "{{ 'March 14, 2016' | date }}",
    @[
      section(SectionType.Output, @[
        token(TkString, "March 14, 2016"),
        token(TkPipe),
        token(TkIdentifier, "date")
      ],
      nodeOutput(@[
        nodeFilter("date", @[nodeString("March 14, 2016")])
      ]))
    ],
    error = true
  )

  testCase(
    "negative timestamp string",
    "{{ '-1152098955' | date: '%m/%d/%Y' }}",
    @[
      section(SectionType.Output, @[
        token(TkString, "-1152098955"),
        token(TkPipe),
        token(TkIdentifier, "date"),
        token(TkColon),
        token(TkString, "%m/%d/%Y")
      ],
      nodeOutput(@[
        nodeFilter("date", @[nodeString("-1152098955"), nodeArgument("", nodeString("%m/%d/%Y"))])
      ])) 
    ],
    output = "-1152098955"
  )

  testCase(
    "seconds since epoch format directive",
    "{{ 'March 14, 2016' | date: '%s' }}",
    @[
      section(SectionType.Output, @[
        token(TkString, "March 14, 2016"),
        token(TkPipe),
        token(TkIdentifier, "date"),
        token(TkColon),
        token(TkString, "%s")
      ],
      nodeOutput(@[
        nodeFilter("date", @[nodeString("March 14, 2016"), nodeArgument("", nodeString("%s"))])
      ]))
    ],
    output = "1457913600"
  )

  testCase(
    "timestamp integer",
    "{{ 1152098955 | date: '%m/%d/%Y' }}",
    @[
      section(SectionType.Output, @[
        token(TkNumber, "1152098955"),
        token(TkPipe),
        token(TkIdentifier, "date"),
        token(TkColon),
        token(TkString, "%m/%d/%Y")
      ],
      nodeOutput(@[
        nodeFilter("date", @[nodeNumber(1152098955), nodeArgument("", nodeString("%m/%d/%Y"))])
      ]))
    ],
    output = "07/05/2006"
  )

  testCase(
    "timestamp string",
    "{{ '1152098955' | date: '%m/%d/%Y' }}",
    @[
      section(SectionType.Output, @[
        token(TkString, "1152098955"),
        token(TkPipe),
        token(TkIdentifier, "date"),
        token(TkColon),
        token(TkString, "%m/%d/%Y")
      ],
      nodeOutput(@[
        nodeFilter("date", @[nodeString("1152098955"), nodeArgument("", nodeString("%m/%d/%Y"))])
      ]))
    ],
    output = "07/05/2006"
  )

  testCase(
    "too many arguments",
    "{{ 'March 14, 2016' | date: '%b %d, %y', 'foo' }}",
    @[
      section(SectionType.Output, @[
        token(TkString, "March 14, 2016"),
        token(TkPipe),
        token(TkIdentifier, "date"),
        token(TkColon),
        token(TkString, "%b %d, %y"),
        token(TkComma),
        token(TkString, "foo")
      ],
      nodeOutput(@[
        nodeFilter("date", @[nodeString("March 14, 2016"), nodeArgument("", nodeString("%b %d, %y")), nodeArgument("", nodeString("foo"))])
      ]))
    ],
    error = true
  )

  testCase(
    "undefined argument",
    "{{ 'March 14, 2016' | date: nosuchthing }}",
    @[
      section(SectionType.Output, @[
        token(TkString, "March 14, 2016"),
        token(TkPipe),
        token(TkIdentifier, "date"),
        token(TkColon),
        token(TkIdentifier, "nosuchthing")
      ],
      nodeOutput(@[
        nodeFilter("date", @[nodeString("March 14, 2016"), nodeArgument("", nodeVariable("nosuchthing"))])
      ]))
    ],
    output = "March 14, 2016"
  )

  testCase(
    "undefined left value",
    "{{ nosuchthing | date: '%b %d, %y' }}",
    @[
      section(SectionType.Output, @[
        token(TkIdentifier, "nosuchthing"),
        token(TkPipe),
        token(TkIdentifier, "date"),
        token(TkColon),
        token(TkString, "%b %d, %y")
      ],
      nodeOutput(@[
        nodeFilter("date", @[nodeVariable("nosuchthing"), nodeArgument("", nodeString("%b %d, %y"))])
      ]))
    ],
    output = ""
  )

  testCase(
    "well formed string",
    "{{ 'March 14, 2016' | date: '%b %d, %y' }}",
    @[
      section(SectionType.Output, @[
        token(TkString, "March 14, 2016"),
        token(TkPipe),
        token(TkIdentifier, "date"),
        token(TkColon),
        token(TkString, "%b %d, %y")
      ],
      nodeOutput(@[
        nodeFilter("date", @[nodeString("March 14, 2016"), nodeArgument("", nodeString("%b %d, %y"))])
      ]))
    ],
    output = "Mar 14, 16"
  )
