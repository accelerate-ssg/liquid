

suite "liquid tag":
  testCase(
    "empty liquid tag",
    "{% liquid %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "liquid")
        ],
        nodeLiquid(@[])
      )
    ]
  )

  testCase(
    "liquid tag with echo",
    "{% liquid echo 'hello' %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "liquid"),
          token(TkIdentifier, "echo"),
          token(TkString, "hello")
        ],
        nodeLiquid(@[
          nodeEcho(@[nodeString("hello")])
        ])
      )
    ]
  )

  testCase(
    "nested liquid with if",
    "{%- if true %}\n  {%- liquid\n    echo \"good\"\n  %}\n{%- endif -%}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "if"),
          token(TkBoolean, "true")
        ],
        nodeIf(nodeBoolean(true))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "liquid"),
          token(TkIdentifier, "echo"),
          token(TkString, "good")
        ],
        nodeLiquid(@[
          nodeEcho(@[nodeString("good")])
        ])
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "liquid tag in liquid tag",
    "{% liquid liquid echo 'bar' echo \"foo\" %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "liquid"),
          token(TkIdentifier, "liquid"),
          token(TkIdentifier, "echo"),
          token(TkString, "bar"),
          token(TkIdentifier, "echo"),
          token(TkString, "foo")
        ],
        nodeLiquid(@[
          nodeLiquid(@[
            nodeEcho(@[nodeString("bar")])
          ]),
          nodeEcho(@[nodeString("foo")])
        ])
      )
    ]
  )

  testCase(
    "whitespace control",
    "Hello,     \n{%- liquid echo ' World! ' -%}\n   Goodbye.",
    @[
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "liquid"),
          token(TkIdentifier, "echo"),
          token(TkString, " World! ")
        ],
        nodeLiquid(@[
          nodeEcho(@[nodeString(" World! ")])
        ])
      ),
      section(
        SectionType.Text,
        @[],
        nil
      )
    ]
  )

  testCase(
    "newline terminated tags",
    "{% liquid\nif product.title\n   echo product.title | upcase\nelse\n   echo 'product-1' | upcase \nendif\n\nfor i in (0..5)\n   echo i\nendfor %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "liquid")
          # TODO: The liquid tag parser will need to handle newline-separated commands
        ],
        nodeLiquid(@[])  # Complex liquid parsing not implemented yet
      )
    ],
    context = %*{"product": {"title": "foo"}},
    output = "FOO012345"
  )