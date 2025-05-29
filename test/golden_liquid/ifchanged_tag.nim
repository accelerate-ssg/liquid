

suite "ifchanged tag":
  testCase(
    "basic ifchanged",
    "{% ifchanged %}hello{% endifchanged %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "ifchanged")
        ],
        nodeIfchanged()
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "endifchanged")
        ],
        nodeEndIfchanged()
      )
    ],
    output = "hello"
  )

  testCase(
    "ifchanged with expression",
    "{% ifchanged foo %}{{ foo }}{% endifchanged %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "ifchanged"),
          token(TkIdentifier, "foo")
        ],
        nodeIfchanged(nodeVariable("foo"))
      ),
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "foo")
        ],
        nodeOutput(@[nodeVariable("foo")])
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "endifchanged")
        ],
        nodeEndIfchanged()
      )
    ],
    context = %*{"foo": "bar"},
    output = "bar"
  )

  testCase(
    "ifchanged with else",
    "{% ifchanged %}hello{% else %}world{% endifchanged %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "ifchanged")
        ],
        nodeIfchanged()
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "else")
        ],
        nodeElse()
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "endifchanged")
        ],
        nodeEndIfchanged()
      )
    ],
    output = "hello"
  )