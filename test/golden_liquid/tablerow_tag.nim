

suite "tablerow tag":
  testCase(
    "one row",
    "{% tablerow tag in collection.tags %}{{ tag }}{% endtablerow %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "tablerow"),
          token(TkIdentifier, "tag"),
          token(TkOperator, "in"),
          token(TkIdentifier, "collection"),
          token(TkDot),
          token(TkIdentifier, "tags")
        ],
        nodeTablerow(
          "tag",
          nodeDot(nodeIdentifier("collection"), "tags"),
          @[nodeOutput(@[nodeIdentifier("tag")])]
        )
      ),
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "endtablerow")
        ],
        nodeEndTablerow()
      )
    ]
  )

  testCase(
    "two columns",
    "{% tablerow tag in collection.tags cols:2 %}{{ tag }}{% endtablerow %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "tablerow"),
          token(TkIdentifier, "tag"),
          token(TkOperator, "in"),
          token(TkIdentifier, "collection"),
          token(TkDot),
          token(TkIdentifier, "tags"),
          token(TkIdentifier, "cols"),
          token(TkColon),
          token(TkNumber, "2")
        ],
        nodeTablerow(
          "tag",
          nodeDot(nodeIdentifier("collection"), "tags"),
          @[nodeOutput(@[nodeIdentifier("tag")])]
        )
      )
    ]
  )

  testCase(
    "one row with limit",
    "{% tablerow tag in collection.tags limit: 2 %}{{ tag }}{% endtablerow %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "tablerow"),
          token(TkIdentifier, "tag"),
          token(TkOperator, "in"),
          token(TkIdentifier, "collection"),
          token(TkDot),
          token(TkIdentifier, "tags"),
          token(TkIdentifier, "limit"),
          token(TkColon),
          token(TkNumber, "2")
        ],
        nodeTablerow(
          "tag",
          nodeDot(nodeIdentifier("collection"), "tags"),
          @[nodeOutput(@[nodeIdentifier("tag")])]
        )
      )
    ]
  )

  testCase(
    "one row with offset",
    "{% tablerow tag in collection.tags offset: 2 %}{{ tag }}{% endtablerow %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "tablerow"),
          token(TkIdentifier, "tag"),
          token(TkOperator, "in"),
          token(TkIdentifier, "collection"),
          token(TkDot),
          token(TkIdentifier, "tags"),
          token(TkIdentifier, "offset"),
          token(TkColon),
          token(TkNumber, "2")
        ],
        nodeTablerow(
          "tag",
          nodeDot(nodeIdentifier("collection"), "tags"),
          @[nodeOutput(@[nodeIdentifier("tag")])]
        )
      )
    ]
  )

  testCase(
    "two column range",
    "{% tablerow i in (1..4) cols:2 %}{{ i }} {{ tablerowloop.col_first }}{% endtablerow %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "tablerow"),
          token(TkIdentifier, "i"),
          token(TkOperator, "in"),
          token(TkLeftParen),
          token(TkNumber, "1"),
          token(TkRange),
          token(TkNumber, "4"),
          token(TkRightParen),
          token(TkIdentifier, "cols"),
          token(TkColon),
          token(TkNumber, "2")
        ],
        nodeTablerow(
          "i",
          nodeRange(nodeLiteral(1), nodeLiteral(4)),
          @[
            nodeOutput(@[nodeIdentifier("i")]),
            nodeOutput(@[
              nodeLiteral(" "),
              nodeDot(nodeIdentifier("tablerowloop"), "col_first")
            ])
          ]
        )
      )
    ]
  )

  testCase(
    "cols is a string",
    "{% tablerow i in (1..4) cols:'2' %}{{ i }} {{ tablerowloop.col_first }}{% endtablerow %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkIdentifier, "tablerow"),
          token(TkIdentifier, "i"),
          token(TkOperator, "in"),
          token(TkLeftParen),
          token(TkNumber, "1"),
          token(TkRange),
          token(TkNumber, "4"),
          token(TkRightParen),
          token(TkIdentifier, "cols"),
          token(TkColon),
          token(TkString, "'2'")
        ],
        nodeTablerow(
          "i",
          nodeRange(nodeLiteral(1), nodeLiteral(4)),
          @[
            nodeOutput(@[nodeIdentifier("i")]),
            nodeOutput(@[
              nodeLiteral(" "),
              nodeDot(nodeIdentifier("tablerowloop"), "col_first")
            ])
          ]
        )
      )
    ]
  )

  # Skip execution tests that require full rendering
  # testCase(
  #   "no cols param (execution)",
  #   "{% tablerow i in (1..2) %}\ncol: {{ tablerowloop.col }}\ncol0: {{ tablerowloop.col0 }}\ncol_first: {{ tablerowloop.col_first }}\ncol_last: {{ tablerowloop.col_last }}\nfirst: {{ tablerowloop.first }}\nindex: {{ tablerowloop.index }}\nindex0: {{ tablerowloop.index0 }}\nlast: {{ tablerowloop.last }}\nlength: {{ tablerowloop.length }}\nrindex: {{ tablerowloop.rindex }}\nrindex0: {{ tablerowloop.rindex0 }}\nrow: {{ tablerowloop.row }}\n{% endtablerow %}",
  #   @[]  # Requires full rendering with tablerowloop object
  # )

  # testCase(
  #   "two column odd range (execution)",
  #   "{% tablerow i in (1..5) cols:2 %}{{ i }} {{ tablerowloop.col_first }}{% endtablerow %}",
  #   @[]  # Requires rendering with HTML output
  # )

  # testCase(
  #   "cols is a float (execution)",
  #   "{% tablerow i in (1..4) cols:2.6 %}{{ i }} {{ tablerowloop.col_first }}{% endtablerow %}",
  #   @[]  # Requires rendering with float to int conversion
  # )