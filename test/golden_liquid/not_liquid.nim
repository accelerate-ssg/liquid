suite "not liquid":
  testCase(
    "css text gets passed through unchanged",
    " div { font-weight: bold; } ",
    @[
      section(
        SectionType.Text,
        @[],
        nil
      )
    ],
    output = " div { font-weight: bold; } "
  )

  testCase(
    "plain text gets passed through unchanged",
    "a literal string",
    @[
      section(
        SectionType.Text,
        @[],
        nil
      )
    ],
    output = "a literal string"
  )