import helpers

suite "if statement":
  testCase(
    "0.0 is truthy",
    "{% if 0.0 %}Hello{% else %}Goodbye{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkNumber, "0.0")
        ],
        nodeIf(nodeNumber(0.0))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "alternate not equal condition",
    "{% if product.title <> 'foo' %}baz{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkIdentifier, "product"),
          token(TkDot),
          token(TkIdentifier, "title"),
          token(TkOperator, "!="),
          token(TkString, "foo")
        ],
        nodeIf(nodeComparison("!=", 
          nodeVariable("product.title"), 
          nodeString("foo")
        ))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ],
    context = %*{"product": {"title": "foo"}}
  )

  testCase(
    "array is equal to array",
    "{% assign x = 'a,b,c' | split: ',' %}{% assign y = 'a,b,c' | split: ',' %}{% if x == y %}true{% else %}false{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "assign"),
          token(TkIdentifier, "x"),
          token(TkAssign),
          token(TkString, "a,b,c"),
          token(TkPipe),
          token(TkIdentifier, "split"),
          token(TkColon),
          token(TkString, ",")
        ],
        nodeAssign("x", nodeFilter("split", @[nodeString("a,b,c"), nodeArgument("", nodeString(","))]))
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "assign"),
          token(TkIdentifier, "y"),
          token(TkAssign),
          token(TkString, "a,b,c"),
          token(TkPipe),
          token(TkIdentifier, "split"),
          token(TkColon),
          token(TkString, ",")
        ],
        nodeAssign("y", nodeFilter("split", @[nodeString("a,b,c"), nodeArgument("", nodeString(","))]))
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkIdentifier, "x"),
          token(TkOperator, "=="),
          token(TkIdentifier, "y")
        ],
        nodeIf(nodeComparison("==", nodeVariable("x"), nodeVariable("y")))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "array is equal to array from context",
    "{% assign y = 'a,b,c' | split: ',' %}{% if x == y %}true{% else %}false{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "assign"),
          token(TkIdentifier, "y"),
          token(TkAssign),
          token(TkString, "a,b,c"),
          token(TkPipe),
          token(TkIdentifier, "split"),
          token(TkColon),
          token(TkString, ",")
        ],
        nodeAssign("y", nodeFilter("split", @[nodeString("a,b,c"), nodeArgument("", nodeString(","))]))
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkIdentifier, "x"),
          token(TkOperator, "=="),
          token(TkIdentifier, "y")
        ],
        nodeIf(nodeComparison("==", nodeVariable("x"), nodeVariable("y")))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ],
    context = %*{"x": ["a", "b", "c"]}
  )

  testCase(
    "blocks that contain only whitespace and comments are not rendered",
    "{% if true %} {% comment %} this is blank {% endcomment %} {% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
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
          token(TkKeyword, "comment")
        ],
        nodeComment()
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
        nodeEndComment()
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "blocks that contain only whitespace are not rendered",
    "{% if true %}  {% elsif false %} {% else %} {% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
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
          token(TkKeyword, "elsif"),
          token(TkBoolean, "false")
        ],
        nodeElsIf(nodeBoolean(false))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "condition with conditional alternative",
    "{% if product.title == 'hello' %}foo{% elsif product.title == 'foo' %}bar{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkIdentifier, "product"),
          token(TkDot),
          token(TkIdentifier, "title"),
          token(TkOperator, "=="),
          token(TkString, "hello")
        ],
        nodeIf(nodeComparison("==", nodeVariable("product.title"), nodeString("hello")))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "elsif"),
          token(TkIdentifier, "product"),
          token(TkDot),
          token(TkIdentifier, "title"),
          token(TkOperator, "=="),
          token(TkString, "foo")
        ],
        nodeElsIf(nodeComparison("==", nodeVariable("product.title"), nodeString("foo")))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ],
    context = %*{"product": {"title": "foo"}}
  )

  testCase(
    "condition with conditional alternative and final alternative",
    "{% if product.title == 'hello' %}foo{% elsif product.title == 'goodbye' %}bar{% else %}baz{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkIdentifier, "product"),
          token(TkDot),
          token(TkIdentifier, "title"),
          token(TkOperator, "=="),
          token(TkString, "hello")
        ],
        nodeIf(nodeComparison("==", nodeVariable("product.title"), nodeString("hello")))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "elsif"),
          token(TkIdentifier, "product"),
          token(TkDot),
          token(TkIdentifier, "title"),
          token(TkOperator, "=="),
          token(TkString, "goodbye")
        ],
        nodeElsIf(nodeComparison("==", nodeVariable("product.title"), nodeString("goodbye")))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ],
    context = %*{"product": {"title": "foo"}}
  )

  testCase(
    "condition with literal consequence",
    "{% if product.title == 'foo' %}bar{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkIdentifier, "product"),
          token(TkDot),
          token(TkIdentifier, "title"),
          token(TkOperator, "=="),
          token(TkString, "foo")
        ],
        nodeIf(nodeComparison("==", nodeVariable("product.title"), nodeString("foo")))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ],
    context = %*{"product": {"title": "foo"}}
  )

  testCase(
    "condition with literal consequence and literal alternative",
    "{% if product.title == 'hello' %}bar{% else %}baz{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkIdentifier, "product"),
          token(TkDot),
          token(TkIdentifier, "title"),
          token(TkOperator, "=="),
          token(TkString, "hello")
        ],
        nodeIf(nodeComparison("==", nodeVariable("product.title"), nodeString("hello")))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ],
    context = %*{"product": {"title": "foo"}}
  )

  testCase(
    "conditional alternative with default",
    "{% if false %}foo{% elsif false %}bar{% else %}hello{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkBoolean, "false")
        ],
        nodeIf(nodeBoolean(false))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "elsif"),
          token(TkBoolean, "false")
        ],
        nodeElsIf(nodeBoolean(false))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "contains condition",
    "{% if product.tags contains 'garden' %}baz{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkIdentifier, "product"),
          token(TkDot),
          token(TkIdentifier, "tags"),
          token(TkOperator, "contains"),
          token(TkString, "garden")
        ],
        nodeIf(nodeComparison("contains", nodeVariable("product.tags"), nodeString("garden")))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}}
  )

  testCase(
    "else tag expressions are ignored",
    "{% if false %}1{% else nonsense %}2{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkBoolean, "false")
        ],
        nodeIf(nodeBoolean(false))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else"),
          token(TkIdentifier, "nonsense")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ],
    strict = true
  )

  testCase(
    "empty array equals special empty",
    "{% if x == empty %}TRUE{% else %}FALSE{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkIdentifier, "x"),
          token(TkOperator, "=="),
          token(TkEmpty)
        ],
        nodeIf(nodeComparison("==", nodeVariable("x"), nodeEmpty()))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ],
    context = %*{"x": []}
  )

  testCase(
    "empty array is truthy",
    "{% if x %}TRUE{% else %}FALSE{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkIdentifier, "x")
        ],
        nodeIf(nodeVariable("x"))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ],
    context = %*{"x": []}
  )

  testCase(
    "empty object equals special empty",
    "{% if x == empty %}TRUE{% else %}FALSE{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkIdentifier, "x"),
          token(TkOperator, "=="),
          token(TkEmpty)
        ],
        nodeIf(nodeComparison("==", nodeVariable("x"), nodeEmpty()))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ],
    context = %*{"x": {}}
  )

  testCase(
    "empty object is truthy",
    "{% if x %}TRUE{% else %}FALSE{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkIdentifier, "x")
        ],
        nodeIf(nodeVariable("x"))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ],
    context = %*{"x": {}}
  )

  testCase(
    "empty string is truthy",
    "{% if '' %}TRUE{% else %}FALSE{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkString, "")
        ],
        nodeIf(nodeString(""))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "extra else blocks are ignored",
    "{% if false %}1{% else %}2{% else %}3{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkBoolean, "false")
        ],
        nodeIf(nodeBoolean(false))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ],
    strict = true
  )

  testCase(
    "extra elsif blocks are ignored",
    "{% if false %}1{% else %}2{% elsif true %}3{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkBoolean, "false")
        ],
        nodeIf(nodeBoolean(false))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "elsif"),
          token(TkBoolean, "true")
        ],
        nodeElsIf(nodeBoolean(true))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ],
    strict = true
  )

  testCase(
    "int does not equal string",
    "{% if 1 == '1' %}true{% else %}false{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkNumber, "1"),
          token(TkOperator, "=="),
          token(TkString, "1")
        ],
        nodeIf(nodeComparison("==", nodeNumber(1), nodeString("1")))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "int equals float",
    "{% if 1 == 1.0 %}true{% else %}false{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkNumber, "1"),
          token(TkOperator, "=="),
          token(TkNumber, "1.0")
        ],
        nodeIf(nodeComparison("==", nodeNumber(1), nodeNumber(1.0)))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "literal false condition",
    "{% if false %}{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkBoolean, "false")
        ],
        nodeIf(nodeBoolean(false))
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "literal nil is falsy",
    "{% if nil %}bar{% else %}foo{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkNil)
        ],
        nodeIf(nodeNil())
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "logical operators are right associative",
    "{% if true and false and false or true %}hello{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkBoolean, "true"),
          token(TkAnd),
          token(TkBoolean, "false"),
          token(TkAnd),
          token(TkBoolean, "false"),
          token(TkOr),
          token(TkBoolean, "true")
        ],
        nodeIf(
          nodeLogical("or",
            nodeLogical("and",
              nodeLogical("and",
                nodeBoolean(true),
                nodeBoolean(false)
              ),
              nodeBoolean(false)
            ),
            nodeBoolean(true)
          )
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "nested condition in the consequence block",
    "{% if product %}{% if title == 'Hello' %}baz{% endif %}{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkIdentifier, "product")
        ],
        nodeIf(nodeVariable("product"))
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkIdentifier, "title"),
          token(TkOperator, "=="),
          token(TkString, "Hello")
        ],
        nodeIf(nodeComparison("==", nodeVariable("title"), nodeString("Hello")))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ],
    context = %*{"product": {"title": "foo"}, "title": "Hello"}
  )

  testCase(
    "nested condition, alternative in the consequence block",
    "{% if product %}{% if title == 'goodbye' %}baz{% else %}hello{% endif %}{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkIdentifier, "product")
        ],
        nodeIf(nodeVariable("product"))
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkIdentifier, "title"),
          token(TkOperator, "=="),
          token(TkString, "goodbye")
        ],
        nodeIf(nodeComparison("==", nodeVariable("title"), nodeString("goodbye")))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ],
    context = %*{"product": {"title": "foo"}, "title": "Hello"}
  )

  testCase(
    "non-empty hash is truthy",
    "{% if product %}bar{% else %}foo{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkIdentifier, "product")
        ],
        nodeIf(nodeVariable("product"))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ],
    context = %*{"product": {"title": "foo"}}
  )

  testCase(
    "not equal condition",
    "{% if product.title != 'foo' %}baz{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkIdentifier, "product"),
          token(TkDot),
          token(TkIdentifier, "title"),
          token(TkOperator, "!="),
          token(TkString, "foo")
        ],
        nodeIf(nodeComparison("!=", nodeVariable("product.title"), nodeString("foo")))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ],
    context = %*{"product": {"title": "foo"}}
  )

  testCase(
    "one is not equal to true",
    "{% if 1 == true %}Hello{% else %}Goodbye{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkNumber, "1"),
          token(TkOperator, "=="),
          token(TkBoolean, "true")
        ],
        nodeIf(nodeComparison("==", nodeNumber(1), nodeBoolean(true)))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "range equals range",
    "{% assign foo = (1..3) %}{% if foo == (1..3) %}true{% else %}false{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "assign"),
          token(TkIdentifier, "foo"),
          token(TkAssign),
          token(TkLeftParen),
          token(TkNumber, "1"),
          token(TkRange),
          token(TkNumber, "3"),
          token(TkRightParen)
        ],
        nodeAssign("foo", nodeRange(nodeNumber(1), nodeNumber(3)))
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkIdentifier, "foo"),
          token(TkOperator, "=="),
          token(TkLeftParen),
          token(TkNumber, "1"),
          token(TkRange),
          token(TkNumber, "3"),
          token(TkRightParen)
        ],
        nodeIf(nodeComparison("==", 
          nodeVariable("foo"), 
          nodeRange(nodeNumber(1), nodeNumber(3))
        ))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "string contains int",
    "{% if 'hel9lo' contains 9 %}TRUE{% else %}FALSE{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkString, "hel9lo"),
          token(TkOperator, "contains"),
          token(TkNumber, "9")
        ],
        nodeIf(nodeComparison("contains", nodeString("hel9lo"), nodeNumber(9)))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ],
    context = %*{"x": {}}
  )

  testCase(
    "string does not equal int",
    "{% if '1' == 1 %}true{% else %}false{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkString, "1"),
          token(TkOperator, "=="),
          token(TkNumber, "1")
        ],
        nodeIf(nodeComparison("==", nodeString("1"), nodeNumber(1)))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "string greater than int",
    "{% if '2' > 1 %}true{% else %}false{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkString, "2"),
          token(TkOperator, ">"),
          token(TkNumber, "1")
        ],
        nodeIf(nodeComparison(">", nodeString("2"), nodeNumber(1)))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ],
    # The original Golden Liquid tests claim this is an error, but testing it in Ruby shows that it is not.
    # error = true
    output = "true"
  )

  testCase(
    "string is greater than or equal to string",
    "{% if 'abc' >= 'acb' %}true{% else %}false{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkString, "abc"),
          token(TkOperator, ">="),
          token(TkString, "acb")
        ],
        nodeIf(nodeComparison(">=", nodeString("abc"), nodeString("acb")))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "string is greater than string",
    "{% if 'abc' > 'acb' %}true{% else %}false{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkString, "abc"),
          token(TkOperator, ">"),
          token(TkString, "acb")
        ],
        nodeIf(nodeComparison(">", nodeString("abc"), nodeString("acb")))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "string is less than or equal to string",
    "{% if 'abc' <= 'acb' %}true{% else %}false{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkString, "abc"),
          token(TkOperator, "<="),
          token(TkString, "acb")
        ],
        nodeIf(nodeComparison("<=", nodeString("abc"), nodeString("acb")))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "string is less than string",
    "{% if 'abc' < 'acb' %}true{% else %}false{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkString, "abc"),
          token(TkOperator, "<"),
          token(TkString, "acb")
        ],
        nodeIf(nodeComparison("<", nodeString("abc"), nodeString("acb")))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "string is not greater than or equal to string",
    "{% if 'bbb' >= 'aaa' %}true{% else %}false{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkString, "bbb"),
          token(TkOperator, ">="),
          token(TkString, "aaa")
        ],
        nodeIf(nodeComparison(">=", nodeString("bbb"), nodeString("aaa")))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "string is not greater than string",
    "{% if 'bbb' > 'aaa' %}true{% else %}false{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkString, "bbb"),
          token(TkOperator, ">"),
          token(TkString, "aaa")
        ],
        nodeIf(nodeComparison(">", nodeString("bbb"), nodeString("aaa")))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "string is not less than or equal to string",
    "{% if 'bbb' <= 'aaa' %}true{% else %}false{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkString, "bbb"),
          token(TkOperator, "<="),
          token(TkString, "aaa")
        ],
        nodeIf(nodeComparison("<=", nodeString("bbb"), nodeString("aaa")))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "string is not less than string",
    "{% if 'bbb' < 'aaa' %}true{% else %}false{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkString, "bbb"),
          token(TkOperator, "<"),
          token(TkString, "aaa")
        ],
        nodeIf(nodeComparison("<", nodeString("bbb"), nodeString("aaa")))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "undefined is equal to nil",
    "{% if nosuchthing == nil %}TRUE{% else %}FALSE{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkIdentifier, "nosuchthing"),
          token(TkOperator, "=="),
          token(TkNil)
        ],
        nodeIf(nodeComparison("==", nodeVariable("nosuchthing"), nodeNil()))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "undefined is equal to null",
    "{% if nosuchthing == null %}TRUE{% else %}FALSE{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkIdentifier, "nosuchthing"),
          token(TkOperator, "=="),
          token(TkNil)
        ],
        nodeIf(nodeComparison("==", nodeVariable("nosuchthing"), nodeNil()))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "undefined variables are falsy",
    "{% if nosuchthing %}bar{% else %}foo{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkIdentifier, "nosuchthing")
        ],
        nodeIf(nodeVariable("nosuchthing"))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "zero is not equal to false",
    "{% if 0 == false %}Hello{% else %}Goodbye{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkNumber, "0"),
          token(TkOperator, "=="),
          token(TkBoolean, "false")
        ],
        nodeIf(nodeComparison("==", nodeNumber(0), nodeBoolean(false)))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

  testCase(
    "zero is truthy",
    "{% if 0 %}Hello{% else %}Goodbye{% endif %}",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "if"),
          token(TkNumber, "0")
        ],
        nodeIf(nodeNumber(0))
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "else")
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
          token(TkKeyword, "endif")
        ],
        nodeEndIf()
      )
    ]
  )

