

suite "case/when":
  testCase(
    "'when' expression using an identifier",
    "{% case title %}{% when other %}foo{% when 'goodbye' %}bar{% endcase %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "case"),
          token(TkIdentifier, "title")
        ],
        nodeCase("title")
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "when"),
          token(TkIdentifier, "other")
        ],
        nodeWhen(nodeVariable("other"))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "when"),
          token(TkString, "goodbye")
        ],
        nodeWhen(nodeString("goodbye"))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "endcase")
        ],
        nodeEndCase()
      )
    ],
    context = %*{"title": "Hello", "other": "Hello"},
    output = "foo"
  )

  testCase(
    "'when' expression using an out of scope identifier",
    "{% case title %}{% when nosuchthing %}foo{% when 'Hello' %}bar{% endcase %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "case"),
          token(TkIdentifier, "title")
        ],
        nodeCase("title")
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "when"),
          token(TkIdentifier, "nosuchthing")
        ],
        nodeWhen(nodeVariable("nosuchthing"))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "when"),
          token(TkString, "Hello")
        ],
        nodeWhen(nodeString("Hello"))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "endcase")
        ],
        nodeEndCase()
      )
    ],
    context = %*{"title": "Hello"},
    output = "bar"
  )

  testCase(
    "comma separated when expression",
    "{% case title %}{% when 'foo' %}foo{% when 'bar', 'Hello' %}bar{% endcase %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "case"),
          token(TkIdentifier, "title")
        ],
        nodeCase("title")
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "when"),
          token(TkString, "foo")
        ],
        nodeWhen(nodeString("foo"))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "when"),
          token(TkString, "bar"),
          token(TkComma),
          token(TkString, "Hello")
        ],
        nodeWhen(@[nodeString("bar"), nodeString("Hello")])
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "endcase")
        ],
        nodeEndCase()
      )
    ],
    context = %*{"title": "Hello"},
    output = "bar"
  )

  testCase(
    "'or' separated when expression",
    "{% case title %}{% when 'foo' %}foo{% when 'bar' or 'Hello' %}bar{% endcase %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "case"),
          token(TkIdentifier, "title")
        ],
        nodeCase("title")
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "when"),
          token(TkString, "foo")
        ],
        nodeWhen(nodeString("foo"))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "when"),
          token(TkString, "bar"),
          token(TkOr),
          token(TkString, "Hello")
        ],
        nodeWhen(@[nodeString("bar"), nodeString("Hello")])
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "endcase")
        ],
        nodeEndCase()
      )
    ],
    context = %*{"title": "Hello"},
    output = "bar"
  )

  testCase(
    "comma string literal",
    "{% case foo %}{% when 'foo' %}bar{% when ',' %}comma{% endcase %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "case"),
          token(TkIdentifier, "foo")
        ],
        nodeCase("foo")
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "when"),
          token(TkString, "foo")
        ],
        nodeWhen(nodeString("foo"))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "when"),
          token(TkString, ",")
        ],
        nodeWhen(nodeString(","))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "endcase")
        ],
        nodeEndCase()
      )
    ],
    context = %*{"foo": ","},
    output = "comma"
  )

  testCase(
    "empty when tag",
    "{% case foo %}{% when %}bar{% endcase %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "case"),
          token(TkIdentifier, "foo")
        ],
        nodeCase("foo")
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "when")
        ],
        nodeWhen(nil)
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "endcase")
        ],
        nodeEndCase()
      )
    ],
    context = %*{"foo": "bar"},
    error = true
  )

  testCase(
    "with default",
    "{% case title %}{% when 'foo' %}foo{% else %}bar{% endcase %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "case"),
          token(TkIdentifier, "title")
        ],
        nodeCase("title")
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "when"),
          token(TkString, "foo")
        ],
        nodeWhen(nodeString("foo"))
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
          token(TkIdentifier, "endcase")
        ],
        nodeEndCase()
      )
    ],
    context = %*{"title": "Hello"},
    output = "bar"
  )
