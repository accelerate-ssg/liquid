

suite "unless tag":
  testCase(
    "literal false condition",
    "{% unless false %}foo{% endunless %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "unless"),
          token(TkBoolean, "false")
        ],
        nodeUnless(
          nodeLiteral(false)
        )
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "endunless")
        ],
        nodeEndUnless()
      )
    ],
    output = "foo"
  )

  testCase(
    "literal true condition",
    "{% unless true %}foo{% endunless %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "unless"),
          token(TkBoolean, "true")
        ],
        nodeUnless(
          nodeLiteral(true)
        )
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "endunless")
        ],
        nodeEndUnless()
      )
    ]
  )

  testCase(
    "alternative block",
    "{% unless true %}foo{% else %}bar{% endunless %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "unless"),
          token(TkBoolean, "true")
        ],
        nodeUnless(
          nodeLiteral(true)
        )
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
          token(TkIdentifier, "endunless")
        ],
        nodeEndUnless()
      )
    ],
    output = "bar"
  )

  testCase(
    "conditional alternative block",
    "{% unless true %}foo{% elsif true %}bar{% endunless %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "unless"),
          token(TkBoolean, "true")
        ],
        nodeUnless(
          nodeLiteral(true)
        )
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "elsif"),
          token(TkBoolean, "true")
        ],
        nodeElsIf(nodeLiteral(true))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "endunless")
        ],
        nodeEndUnless()
      )
    ],
    output = "bar"
  )

  testCase(
    "conditional alternative block with default",
    "{% unless true %}foo{% elsif false %}bar{% else %}hello{% endunless %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "unless"),
          token(TkBoolean, "true")
        ],
        nodeUnless(
          nodeLiteral(true)
        )
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "elsif"),
          token(TkBoolean, "false")
        ],
        nodeElsIf(nodeLiteral(false))
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
          token(TkIdentifier, "endunless")
        ],
        nodeEndUnless()
      )
    ],
    output = "hello"
  )

  testCase(
    "blocks that contain only whitespace are not rendered",
    "{% unless false %}  {% endunless %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "unless"),
          token(TkBoolean, "false")
        ],
        nodeUnless(
          nodeLiteral(false)
        )
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "endunless")
        ],
        nodeEndUnless()
      )
    ]
  )

  testCase(
    "one is not equal to true",
    "{% unless 1 == true %}Hello{% else %}Goodbye{% endunless %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "unless"),
          token(TkNumber, "1"),
          token(TkOperator, "=="),
          token(TkBoolean, "true")
        ],
        nodeUnless(
          nodeEq(nodeLiteral(1), nodeLiteral(true))
        )
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
          token(TkIdentifier, "endunless")
        ],
        nodeEndUnless()
      )
    ]
  )

  testCase(
    "zero is not equal to false",
    "{% unless 0 == false %}Hello{% else %}Goodbye{% endunless %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "unless"),
          token(TkNumber, "0"),
          token(TkOperator, "=="),
          token(TkBoolean, "false")
        ],
        nodeUnless(
          nodeEq(nodeLiteral(0), nodeLiteral(false))
        )
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
          token(TkIdentifier, "endunless")
        ],
        nodeEndUnless()
      )
    ],
    output = "Hello"
  )

  testCase(
    "zero is truthy",
    "{% unless 0 %}Hello{% else %}Goodbye{% endunless %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "unless"),
          token(TkNumber, "0")
        ],
        nodeUnless(
          nodeLiteral(0)
        )
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
          token(TkIdentifier, "endunless")
        ],
        nodeEndUnless()
      )
    ],
    output = "Goodbye"
  )

  # Skip tests that depend on execution
  # testCase(
  #   "else tag expressions are ignored",
  #   "{% unless true %}1{% else nonsense %}2{% endunless %}",
  #   @[]  # Parser should handle extra tokens after else
  # )

  # testCase(
  #   "extra else blocks are ignored",
  #   "{% unless true %}1{% else %}2{% else %}3{% endunless %}",
  #   @[]  # Parser should handle multiple else blocks
  # )

  # testCase(
  #   "extra elsif blocks are ignored",
  #   "{% unless true %}1{% else %}2{% elsif true %}3{% endunless %}",
  #   @[]  # Parser should handle elsif after else
  # )

  # testCase(
  #   "array is equal to array",
  #   "{% assign x = 'a,b,c' | split: ',' %}{% assign y = 'a,b,c' | split: ',' %}{% unless x == y %}true{% else %}false{% endunless %}",
  #   @[]  # Requires execution
  # )

  # testCase(
  #   "array is equal to array from context",
  #   "{% assign y = 'a,b,c' | split: ',' %}{% unless x == y %}true{% else %}false{% endunless %}",
  #   @[]  # Requires execution
  # )