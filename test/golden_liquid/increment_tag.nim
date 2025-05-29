

suite "increment tag":
  testCase(
    "basic increment",
    "{% increment foo %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "increment"),
          token(TkIdentifier, "foo")
        ],
        nodeIncrement("foo")
      )
    ],
    output = "0"
  )
  
  testCase(
    "increment twice",
    "{% increment foo %} {% increment foo %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "increment"),
          token(TkIdentifier, "foo")
        ],
        nodeIncrement("foo")
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "increment"),
          token(TkIdentifier, "foo")
        ],
        nodeIncrement("foo")
      )
    ],
    output = "0 1"
  )
  
  testCase(
    "increment and variable access",
    "{% increment foo %} {{ foo }}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "increment"),
          token(TkIdentifier, "foo")
        ],
        nodeIncrement("foo")
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "foo")
        ],
        nodeOutput(@[nodeVariable("foo")])
      )
    ],
    output = "0 1"
  )