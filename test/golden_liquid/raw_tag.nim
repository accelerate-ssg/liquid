

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
        SectionType.Text,
        @[],
        nil
      )
    ],
    output = " {% some raw content %} a literal"
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
    ],
    output = "foo"
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
    ],
    output = " %} {% }} {{ "
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
    ],
    output = "{{ foo }}"
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
    ],
    output = "{% assign x = 1 %}"
  )
