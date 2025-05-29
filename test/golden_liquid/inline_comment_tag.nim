suite "inline comment tag":
  testCase(
    "can't comment tags",
    "{%- # {% echo 'hello world' %} -%}",
    @[
      section(
        SectionType.Text,
        @[],
        nil
      )
    ],
    output = " -%}"
  )

  testCase(
    "comment with double quote",
    "{%# some \"comment %}",
    @[],  # Inline comments produce no sections
    output = ""
  )

  testCase(
    "comment with newline",
    "{%#\nsome comment\n%}",
    @[],  # Inline comments produce no sections
    output = ""
  )

  testCase(
    "comment with single quote",
    "{%# some 'comment %}",
    @[],  # Inline comments produce no sections
    output = ""
  )

  testCase(
    "comment with tag delimiter",
    "{%#%}",
    @[],  # Inline comments produce no sections
    output = ""
  )

  testCase(
    "inline tag comment does not require whitespace",
    "some {%#comment%} here",
    @[
      section(
        SectionType.Text,
        @[],
        nil
      )
    ],
    output = "some  here"
  )

  testCase(
    "liquid inline comment",
    "{%- liquid\n  # first comment\n  assign my_variable = 'hello'\n  # second comment\n-%}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "liquid"),
          token(TkNewline, "\n"),
          token(TkSymbol, "#"),
          token(TkNewline, "\n"),
          token(TkIdentifier, "assign"),
          token(TkIdentifier, "my_variable"),
          token(TkAssign, "="),
          token(TkString, "hello"),
          token(TkNewline, "\n"),
          token(TkSymbol, "#")
        ],
        nodeLiquid(@[
          nodeAssign("my_variable", nodeString("hello"))
        ])
      )
    ],
    output = ""
  )

  testCase(
    "liquid inline comment on last line",
    "{%- liquid\n  # first comment\n  assign my_variable = 'hello'\n  # second comment -%}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "liquid"),
          token(TkNewline, "\n"),
          token(TkSymbol, "#"),
          token(TkNewline, "\n"),
          token(TkIdentifier, "assign"),
          token(TkIdentifier, "my_variable"),
          token(TkAssign, "="),
          token(TkString, "hello"),
          token(TkNewline, "\n"),
          token(TkSymbol, "#")
        ],
        nodeLiquid(@[
          nodeAssign("my_variable", nodeString("hello"))
        ])
      )
    ],
    output = ""
  )

  testCase(
    "liquid tag comment using legacy syntax",
    "{%- liquid # first comment -%}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "liquid"),
          token(TkSymbol, "#")
        ],
        nodeLiquid(@[])
      )
    ],
    output = ""
  )

  testCase(
    "no whitespace control",
    "{%# some comment %}",
    @[],  # Inline comments produce no sections
    output = ""
  )

  testCase(
    "tag delimiter can be commented out",
    "{%#}%}",
    @[],  # Inline comments produce no sections
    output = ""
  )

  testCase(
    "whitespace and newlines are not required",
    "{%#some comment%}",
    @[],  # Inline comments produce no sections
    output = ""
  )

  testCase(
    "whitespace control",
    "\t{%- #comment -%} \r\n",
    @[
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkSymbol, "#")
        ],
        Node(kind: nkTag, tagName: "#", parameters: @[])
      ),
      section(
        SectionType.Text,
        @[],
        nil
      )
    ],
    output = ""
  )

  testCase(
    "whitespace control either side",
    "\r{%- #comment -%}\t",
    @[
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkSymbol, "#")
        ],
        Node(kind: nkTag, tagName: "#", parameters: @[])
      ),
      section(
        SectionType.Text,
        @[],
        nil
      )
    ],
    output = ""
  )

  testCase(
    "whitespace control leading",
    "\n{%- # some comment %}  ",
    @[
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkSymbol, "#")
        ],
        Node(kind: nkTag, tagName: "#", parameters: @[])
      ),
      section(
        SectionType.Text,
        @[],
        nil
      )
    ],
    output = "  "
  )

  testCase(
    "whitespace control trailing",
    "   {%# some comment -%}\r",
    @[
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkSymbol, "#")
        ],
        Node(kind: nkTag, tagName: "#", parameters: @[])
      ),
      section(
        SectionType.Text,
        @[],
        nil
      )
    ],
    output = "   "
  )