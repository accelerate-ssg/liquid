import helpers

suite "comment tag":
  testCase(
    "don't render comments",
    "{% comment %}foo{% endcomment %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "comment")
        ],
        nodeComment(),
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "endcomment")
        ],
        nodeEndComment(),
      )
    ],
    output = ""
  )

  testCase(
    "don't render comments with tags",
    "{% comment %}{% if true %}{{ title }}{% endif %}{% endcomment %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "comment")
        ],
        nodeComment(),
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkBoolean, "true"),
        ],
        nodeIf(
          nodeBoolean(true),
        ),
      ),
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "title")
        ],
        nodeOutput(@[
          nodeVariable("title")
        ]),
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "endif")
        ],
        nodeEndIf(),
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "endcomment")
        ],
        nodeEndComment(),
      )
    ],
    output = ""
  )

  testCase(
    "respect whitespace control in comments",
    "\n{%- comment %}foo{% endcomment -%}\t \r",
    @[
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "comment")
        ],
        nodeComment(),
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "endcomment")
        ],
        nodeEndComment(),
      ),
      section(
        SectionType.Text,
        @[],
        nil
      )
    ],
    output = ""
  )
