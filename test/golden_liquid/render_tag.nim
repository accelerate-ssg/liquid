

suite "render tag":
  # Basic render tests - focusing on parsing, not execution
  # The render tag requires partials to be provided in the context
  
  testCase(
    "string literal name",
    "{% render 'product-hero', product: product %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "render"),
          token(TkString, "product-hero"),
          token(TkComma),
          token(TkIdentifier, "product"),
          token(TkColon),
          token(TkIdentifier, "product")
        ],
        nodeRender("product-hero", @[
          ("product", nodeIdentifier("product"))
        ])
      )
    ]
  )

  testCase(
    "render with keyword arguments",
    "{% render 'product-args', foo: 'hello', bar: 'there' %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "render"),
          token(TkString, "product-args"),
          token(TkComma),
          token(TkIdentifier, "foo"),
          token(TkColon),
          token(TkString, "hello"),
          token(TkComma),
          token(TkIdentifier, "bar"),
          token(TkColon),
          token(TkString, "there")
        ],
        nodeRender("product-args", @[
          ("foo", nodeLiteral("hello")),
          ("bar", nodeLiteral("there"))
        ])
      )
    ]
  )

  testCase(
    "render with bound variable",
    "{% render 'product-title' with collection.products[1] %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "render"),
          token(TkString, "product-title"),
          token(TkKeyword, "with"),
          token(TkIdentifier, "collection"),
          token(TkDot),
          token(TkIdentifier, "products"),
          token(TkLeftBracket),
          token(TkNumber, "1"),
          token(TkRightBracket)
        ],
        nodeRender("product-title", nodeIndex(
          nodeDot(nodeIdentifier("collection"), "products"),
          nodeLiteral(1)
        ))
      )
    ]
  )

  testCase(
    "render with bound variable and alias",
    "{% render 'product-alias' with collection.products[1] as product %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "render"),
          token(TkString, "product-alias"),
          token(TkKeyword, "with"),
          token(TkIdentifier, "collection"),
          token(TkDot),
          token(TkIdentifier, "products"),
          token(TkLeftBracket),
          token(TkNumber, "1"),
          token(TkRightBracket),
          token(TkKeyword, "as"),
          token(TkIdentifier, "product")
        ],
        nodeRender("product-alias", 
          nodeIndex(
            nodeDot(nodeIdentifier("collection"), "products"),
            nodeLiteral(1)
          ),
          "product"
        )
      )
    ]
  )

  testCase(
    "render for array",
    "{% render 'prod' for collection.products %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "render"),
          token(TkString, "prod"),
          token(TkIdentifier, "for"),
          token(TkIdentifier, "collection"),
          token(TkDot),
          token(TkIdentifier, "products")
        ],
        nodeRenderFor("prod",
          nodeDot(nodeIdentifier("collection"), "products")
        )
      )
    ]
  )

  # Skip execution tests since they require partial template support
  # testCase(
  #   "assign to keyword argument (execution)",
  #   "{% render 'product-args', foo: 'hello' %}{{ foo }}",
  #   @[]  # Would need execution with partials
  # )

  # testCase(
  #   "assigned variables do not leak into outer scope (execution)",
  #   "{% render 'assign-outer-scope', customer: customer %} {{ last_name }}",
  #   @[]  # Would need execution with partials
  # )

  # testCase(
  #   "forloop helper (execution)",
  #   "{% render 'product' for collection.products %}",
  #   @[]  # Would need execution with partials
  # )