

suite "raw tag":
  testCase(
    "continue after raw",
    "{% raw %} {% some raw content %} {% endraw %}a literal",
    @[
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "raw")],
        nodeRaw(" {% some raw content %} ")
      ),
      section(
        SectionType.Output,
        @[token(TkIdentifier, "a"), token(TkIdentifier, "literal")],
        nodeOutput(@[
          nodeIdentifier("a"),
          nodeIdentifier("literal")
        ])
      )
    ]
  )

  testCase(
    "literal",
    "{% raw %}foo{% endraw %}",
    @[
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "raw")],
        nodeRaw("foo")
      )
    ]
  )

  testCase(
    "partial tag",
    "{% raw %} %} {% }} {{ {% endraw %}",
    @[
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "raw")],
        nodeRaw(" %} {% }} {{ ")
      )
    ]
  )

  testCase(
    "statement",
    "{% raw %}{{ foo }}{% endraw %}",
    @[
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "raw")],
        nodeRaw("{{ foo }}")
      )
    ]
  )

  testCase(
    "tag",
    "{% raw %}{% assign x = 1 %}{% endraw %}",
    @[
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "raw")],
        nodeRaw("{% assign x = 1 %}")
      )
    ]
  )
