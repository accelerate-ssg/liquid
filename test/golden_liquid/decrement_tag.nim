

suite "increment and decrement":
  testCase(
    "increment and decrement named counter",
    "{% decrement foo %} {% decrement foo %} {% increment foo %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "decrement"),
        token(TkIdentifier, "foo")
      ], nodeDecrement("foo")),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[
        token(TkIdentifier, "decrement"),
        token(TkIdentifier, "foo")
      ], nodeDecrement("foo")),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[
        token(TkIdentifier, "increment"),
        token(TkIdentifier, "foo")
      ], nodeIncrement("foo"))
    ],
    output = "-1 -2 -2"
  )

  testCase(
    "named counter",
    "{% decrement foo %}{{ foo }} {% decrement foo %}{{ foo }}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "decrement"),
        token(TkIdentifier, "foo")
      ], nodeDecrement("foo")),
      section(SectionType.Output, @[
        token(TkIdentifier, "foo")
      ], nodeOutput(@[nodeVariable("foo")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[
        token(TkIdentifier, "decrement"),
        token(TkIdentifier, "foo")
      ], nodeDecrement("foo")),
      section(SectionType.Output, @[
        token(TkIdentifier, "foo")
      ], nodeOutput(@[nodeVariable("foo")]))
    ],
    output = "-1-1 -2-2"
  )
