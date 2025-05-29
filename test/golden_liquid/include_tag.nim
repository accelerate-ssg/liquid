

suite "include tag":
  # Include tag requires partial template support which may not be fully implemented
  # Creating basic parsing tests for now
  
  testCase(
    "basic include",
    "{% include 'template' %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "include"),
          token(TkString, "template")
        ],
        Node(kind: nkTag, tagName: "include", parameters: @[nodeString("template")])
      )
    ]
  )
  
  testCase(
    "include with parameters",
    "{% include 'template' foo: 'bar' %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "include"),
          token(TkString, "template"),
          token(TkIdentifier, "foo"),
          token(TkColon),
          token(TkString, "bar")
        ],
        Node(kind: nkTag, tagName: "include", parameters: @[
          nodeString("template"),
          nodeArgument("foo", nodeString("bar"))
        ])
      )
    ]
  )