

suite "loop functionality":
  testCase(
    "access parentloop",
    "{% for i in (1..2)%}{% for j in (1..2) %}{{ i }} {{j}} {{ forloop.parentloop.index }} {{ forloop.index }} {% endfor %}{% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "i"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "2"),
        token(TkRightParen)
      ], nodeFor("i", nodeRange(nodeNumber(1), nodeNumber(2)), @[])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "j"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "2"),
        token(TkRightParen)
      ], nodeFor("j", nodeRange(nodeNumber(1), nodeNumber(2)), @[])),
      section(SectionType.Output, @[token(TkIdentifier, "i")], nodeOutput(@[nodeVariable("i")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[token(TkIdentifier, "j")], nodeOutput(@[nodeVariable("j")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "parentloop"),
        token(TkDot),
        token(TkIdentifier, "index")
      ], nodeOutput(@[nodeVariable("forloop.parentloop.index")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "index")
      ], nodeOutput(@[nodeVariable("forloop.index")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor()),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    output = "1 1 1 1 1 2 1 2 2 1 2 1 2 2 2 2 "
  )

  testCase(
    "assign inside loop",
    "{% for tag in product.tags %}{% assign x = tag %}{% endfor %}{{ x }}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "in"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "tags")
      ], nodeFor("tag", nodeVariable("product.tags"), @[])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "assign"),
        token(TkIdentifier, "x"),
        token(TkAssign),
        token(TkIdentifier, "tag")
      ], nodeAssign("x", nodeVariable("tag"))),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor()),
      section(SectionType.Output, @[token(TkIdentifier, "x")], nodeOutput(@[nodeVariable("x")]))
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "garden"
  )

  testCase(
    "blank empty loops",
    "{% for i in (0..10) %}  {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "i"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "0"),
        token(TkRange),
        token(TkNumber, "10"),
        token(TkRightParen)
      ], nodeFor("i", nodeRange(nodeNumber(0), nodeNumber(10)), @[])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    output = ""
  )

  testCase(
    "break",
    "{% for tag in product.tags %}{% if tag == 'sports' %}{% break %}{% else %}{{ tag }} {% endif %}{% else %}no images{% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "in"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "tags")
      ], nodeFor("tag", nodeVariable("product.tags"), @[])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "if"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "=="),
        token(TkString, "sports")
      ], nodeIf(nodeComparison("==", nodeVariable("tag"), nodeString("sports")))),
      section(SectionType.Tag, @[token(TkIdentifier, "break")], nodeBreak()),
      section(SectionType.Tag, @[token(TkIdentifier, "else")], nodeElse()),
      section(SectionType.Output, @[token(TkIdentifier, "tag")], nodeOutput(@[nodeVariable("tag")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endif")], nodeEndIf()),
      section(SectionType.Tag, @[token(TkIdentifier, "else")], nodeElse()),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = ""
  )

  testCase(
    "comma separated arguments",
    "{% for i in (1..6), limit: 4, offset: 2 %}{{ i }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "i"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "6"),
        token(TkRightParen),
        token(TkComma),
        token(TkIdentifier, "limit"),
        token(TkColon),
        token(TkNumber, "4"),
        token(TkComma),
        token(TkIdentifier, "offset"),
        token(TkColon),
        token(TkNumber, "2")
      ], nodeFor("i", nodeRange(nodeNumber(1), nodeNumber(6)), @[
        nodeArgument("limit", nodeNumber(4)),
        nodeArgument("offset", nodeNumber(2))
      ])),
      section(SectionType.Output, @[token(TkIdentifier, "i")], nodeOutput(@[nodeVariable("i")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    output = "3 4 5 6 "
  )

  testCase(
    "continue",
    "{% for tag in product.tags %}{% if tag == 'sports' %}{% continue %}{% else %}{{ tag }} {% endif %}{% else %}no images{% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "in"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "tags")
      ], nodeFor("tag", nodeVariable("product.tags"), @[])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "if"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "=="),
        token(TkString, "sports")
      ], nodeIf(nodeComparison("==", nodeVariable("tag"), nodeString("sports")))),
      section(SectionType.Tag, @[token(TkIdentifier, "continue")], nodeContinue()),
      section(SectionType.Tag, @[token(TkIdentifier, "else")], nodeElse()),
      section(SectionType.Output, @[token(TkIdentifier, "tag")], nodeOutput(@[nodeVariable("tag")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endif")], nodeEndIf()),
      section(SectionType.Tag, @[token(TkIdentifier, "else")], nodeElse()),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "garden "
  )

  testCase(
    "continue a loop",
    "{% for item in array limit: 3 %}a{{ item }} {% endfor %}{% for item in array offset: continue %}b{{ item }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "item"),
        token(TkOperator, "in"),
        token(TkIdentifier, "array"),
        token(TkIdentifier, "limit"),
        token(TkColon),
        token(TkNumber, "3")
      ], nodeFor("item", nodeVariable("array"), @[nodeArgument("limit", nodeNumber(3))])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[token(TkIdentifier, "item")], nodeOutput(@[nodeVariable("item")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor()),
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "item"),
        token(TkOperator, "in"),
        token(TkIdentifier, "array"),
        token(TkIdentifier, "offset"),
        token(TkColon),
        token(TkIdentifier, "continue")
      ], nodeFor("item", nodeVariable("array"), @[nodeArgument("offset", nodeContinue())])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[token(TkIdentifier, "item")], nodeOutput(@[nodeVariable("item")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"array": [1, 2, 3, 4, 5, 6]},
    output = "a1 a2 a3 b4 b5 b6 "
  )

  testCase(
    "continue a loop over a changing array",
    "{% assign foo = '1,2,3,4,5,6' | split: ',' %}{% for item in foo limit: 3 %}{{ item }} {% endfor %}{% assign foo = 'u,v,w,x,y,z' | split: ',' %}{% for item in foo offset: continue %}{{ item }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "assign"),
        token(TkIdentifier, "foo"),
        token(TkAssign),
        token(TkString, "1,2,3,4,5,6"),
        token(TkPipe),
        token(TkIdentifier, "split"),
        token(TkColon),
        token(TkString, ",")
      ], nodeAssign("foo", nodeFilter("split", @[nodeString("1,2,3,4,5,6"), nodeArgument("",nodeString(","))]))),
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "item"),
        token(TkOperator, "in"),
        token(TkIdentifier, "foo"),
        token(TkIdentifier, "limit"),
        token(TkColon),
        token(TkNumber, "3")
      ], nodeFor("item", nodeVariable("foo"), @[nodeArgument("limit", nodeNumber(3))])),
      section(SectionType.Output, @[token(TkIdentifier, "item")], nodeOutput(@[nodeVariable("item")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor()),
      section(SectionType.Tag, @[
        token(TkIdentifier, "assign"),
        token(TkIdentifier, "foo"),
        token(TkAssign),
        token(TkString, "u,v,w,x,y,z"),
        token(TkPipe),
        token(TkIdentifier, "split"),
        token(TkColon),
        token(TkString, ",")
      ], nodeAssign("foo", nodeFilter("split", @[nodeString("u,v,w,x,y,z"), nodeArgument("",nodeString(","))]))),
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "item"),
        token(TkOperator, "in"),
        token(TkIdentifier, "foo"),
        token(TkIdentifier, "offset"),
        token(TkColon),
        token(TkIdentifier, "continue")
      ], nodeFor("item", nodeVariable("foo"), @[nodeArgument("offset", nodeContinue())])),
      section(SectionType.Output, @[token(TkIdentifier, "item")], nodeOutput(@[nodeVariable("item")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    output = "1 2 3 x y z "
  )

  testCase(
    "continue a loop over an assigned range",
    "{% assign nums = (1..5) %}{% for item in nums limit: 3 %}a{{ item }} {% endfor %}{% for item in nums offset: continue %}b{{ item }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "assign"),
        token(TkIdentifier, "nums"),
        token(TkAssign),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "5"),
        token(TkRightParen)
      ], nodeAssign("nums", nodeRange(nodeNumber(1), nodeNumber(5)))),
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "item"),
        token(TkOperator, "in"),
        token(TkIdentifier, "nums"),
        token(TkIdentifier, "limit"),
        token(TkColon),
        token(TkNumber, "3")
      ], nodeFor("item", nodeVariable("nums"), @[nodeArgument("limit", nodeNumber(3))])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[token(TkIdentifier, "item")], nodeOutput(@[nodeVariable("item")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor()),
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "item"),
        token(TkOperator, "in"),
        token(TkIdentifier, "nums"),
        token(TkIdentifier, "offset"),
        token(TkColon),
        token(TkIdentifier, "continue")
      ], nodeFor("item", nodeVariable("nums"), @[nodeArgument("offset", nodeContinue())])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[token(TkIdentifier, "item")], nodeOutput(@[nodeVariable("item")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    output = "a1 a2 a3 b4 b5 "
  )

  testCase(
    "continue from a limit that is greater than length",
    "{% for item in array limit: 99 %}a{{ item }} {% endfor %}{% for item in array offset: continue %}b{{ item }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "item"),
        token(TkOperator, "in"),
        token(TkIdentifier, "array"),
        token(TkIdentifier, "limit"),
        token(TkColon),
        token(TkNumber, "99")
      ], nodeFor("item", nodeVariable("array"), @[nodeArgument("limit", nodeNumber(99))])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[token(TkIdentifier, "item")], nodeOutput(@[nodeVariable("item")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor()),
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "item"),
        token(TkOperator, "in"),
        token(TkIdentifier, "array"),
        token(TkIdentifier, "offset"),
        token(TkColon),
        token(TkIdentifier, "continue")
      ], nodeFor("item", nodeVariable("array"), @[nodeArgument("offset", nodeContinue())])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[token(TkIdentifier, "item")], nodeOutput(@[nodeVariable("item")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"array": [1, 2, 3, 4, 5, 6]},
    output = "a1 a2 a3 a4 a5 a6 "
  )

  testCase(
    "continue from a range expression",
    "{% for item in (1..6) limit: 3 %}a{{ item }} {% endfor %}{% for item in (1..6) offset: continue %}b{{ item }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "item"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "6"),
        token(TkRightParen),
        token(TkIdentifier, "limit"),
        token(TkColon),
        token(TkNumber, "3")
      ], nodeFor("item", nodeRange(nodeNumber(1), nodeNumber(6)), @[nodeArgument("limit", nodeNumber(3))])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[token(TkIdentifier, "item")], nodeOutput(@[nodeVariable("item")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor()),
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "item"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "6"),
        token(TkRightParen),
        token(TkIdentifier, "offset"),
        token(TkColon),
        token(TkIdentifier, "continue")
      ], nodeFor("item", nodeRange(nodeNumber(1), nodeNumber(6)), @[nodeArgument("offset", nodeContinue())])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[token(TkIdentifier, "item")], nodeOutput(@[nodeVariable("item")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"array": [1, 2, 3, 4, 5, 6]},
    output = "a1 a2 a3 b4 b5 b6 "
  )

  testCase(
    "continue with changing loop var",
    "{% for foo in array limit: 3 %}{{ foo }} {% endfor %}{% for bar in array offset: continue %}{{ bar }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "foo"),
        token(TkOperator, "in"),
        token(TkIdentifier, "array"),
        token(TkIdentifier, "limit"),
        token(TkColon),
        token(TkNumber, "3")
      ], nodeFor("foo", nodeVariable("array"), @[nodeArgument("limit", nodeNumber(3))])),
      section(SectionType.Output, @[token(TkIdentifier, "foo")], nodeOutput(@[nodeVariable("foo")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor()),
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "bar"),
        token(TkOperator, "in"),
        token(TkIdentifier, "array"),
        token(TkIdentifier, "offset"),
        token(TkColon),
        token(TkIdentifier, "continue")
      ], nodeFor("bar", nodeVariable("array"), @[nodeArgument("offset", nodeContinue())])),
      section(SectionType.Output, @[token(TkIdentifier, "bar")], nodeOutput(@[nodeVariable("bar")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"array": [1, 2, 3, 4, 5, 6]},
    output = "1 2 3 4 5 6 "
  )

  testCase(
    "empty array with default",
    "{% for img in emptythings.array %}{{ img.url }} {% else %}no images{% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "img"),
        token(TkOperator, "in"),
        token(TkIdentifier, "emptythings"),
        token(TkDot),
        token(TkIdentifier, "array")
      ], nodeFor("img", nodeVariable("emptythings.array"), @[])),
      section(SectionType.Output, @[
        token(TkIdentifier, "img"),
        token(TkDot),
        token(TkIdentifier, "url")
      ], nodeOutput(@[nodeVariable("img.url")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "else")], nodeElse()),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"emptythings": {"array": [], "map": {}, "string": ""}},
    output = "no images"
  )

  testCase(
    "first and last with an offset and limit",
    "{% for tag in tags limit: 2 offset: 1 %}{{ tag }} {{ forloop.first }} {{ forloop.last }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "in"),
        token(TkIdentifier, "tags"),
        token(TkIdentifier, "limit"),
        token(TkColon),
        token(TkNumber, "2"),
        token(TkIdentifier, "offset"),
        token(TkColon),
        token(TkNumber, "1")
      ], nodeFor("tag", nodeVariable("tags"), @[
        nodeArgument("limit", nodeNumber(2)),
        nodeArgument("offset", nodeNumber(1))
      ])),
      section(SectionType.Output, @[token(TkIdentifier, "tag")], nodeOutput(@[nodeVariable("tag")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "first")
      ], nodeOutput(@[nodeVariable("forloop.first")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "last")
      ], nodeOutput(@[nodeVariable("forloop.last")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"tags": ["sports", "garden", "home", "diy", "motoring", "fashion"]},
    output = "garden true false home false true "
  )

  testCase(
    "first and last with offset continue",
    "{% for tag in product.tags limit: 1 %}{% endfor %}{% for tag in product.tags offset: continue %}{{ forloop.first }} {{ forloop.last }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "in"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "tags"),
        token(TkIdentifier, "limit"),
        token(TkColon),
        token(TkNumber, "1")
      ], nodeFor("tag", nodeVariable("product.tags"), @[nodeArgument("limit", nodeNumber(1))])),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor()),
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "in"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "tags"),
        token(TkIdentifier, "offset"),
        token(TkColon),
        token(TkIdentifier, "continue")
      ], nodeFor("tag", nodeVariable("product.tags"), @[nodeArgument("offset", nodeContinue())])),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "first")
      ], nodeOutput(@[nodeVariable("forloop.first")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "last")
      ], nodeOutput(@[nodeVariable("forloop.last")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"product": {"tags": ["sports", "garden", "home", "diy", "motoring", "fashion"]}},
    output = "true false false false false false false false false true "
  )

  testCase(
    "forloop goes out of scope",
    "{% for tag in product.tags %}{{ forloop.length }} {% endfor %}{{ forloop.length }}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "in"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "tags")
      ], nodeFor("tag", nodeVariable("product.tags"), @[])),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "length")
      ], nodeOutput(@[nodeVariable("forloop.length")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor()),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "length")
      ], nodeOutput(@[nodeVariable("forloop.length")]))
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "2 2 "
  )

  testCase(
    "forloop length",
    "{% for tag in product.tags %}{{ forloop.length }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "in"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "tags")
      ], nodeFor("tag", nodeVariable("product.tags"), @[])),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "length")
      ], nodeOutput(@[nodeVariable("forloop.length")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "2 2 "
  )

  testCase(
    "forloop length with limit",
    "{% for tag in tags limit:3 %}{{ forloop.length }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "in"),
        token(TkIdentifier, "tags"),
        token(TkIdentifier, "limit"),
        token(TkColon),
        token(TkNumber, "3")
      ], nodeFor("tag", nodeVariable("tags"), @[nodeArgument("limit", nodeNumber(3))])),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "length")
      ], nodeOutput(@[nodeVariable("forloop.length")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"tags": ["sports", "garden", "home", "diy", "motoring", "fashion"]},
    output = "3 3 3 "
  )

  testCase(
    "forloop length with offset",
    "{% for tag in tags offset:3 %}{{ forloop.length }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "in"),
        token(TkIdentifier, "tags"),
        token(TkIdentifier, "offset"),
        token(TkColon),
        token(TkNumber, "3")
      ], nodeFor("tag", nodeVariable("tags"), @[nodeArgument("offset", nodeNumber(3))])),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "length")
      ], nodeOutput(@[nodeVariable("forloop.length")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"tags": ["sports", "garden", "home", "diy", "motoring", "fashion"]},
    output = "3 3 3 "
  )

  testCase(
    "forloop name",
    "{% for tag in product.tags limit:1 %}{{ forloop.name }}{% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "in"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "tags"),
        token(TkIdentifier, "limit"),
        token(TkColon),
        token(TkNumber, "1")
      ], nodeFor("tag", nodeVariable("product.tags"), @[nodeArgument("limit", nodeNumber(1))])),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "name")
      ], nodeOutput(@[nodeVariable("forloop.name")])),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "tag-product.tags"
  )
  
  testCase(
    "forloop name of a range",
    "{% for i in (1..3) limit:1 %}{{ forloop.name }}{% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "i"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "3"),
        token(TkRightParen),
        token(TkIdentifier, "limit"),
        token(TkColon),
        token(TkNumber, "1")
      ], nodeFor("i", nodeRange(nodeNumber(1), nodeNumber(3)), @[nodeArgument("limit", nodeNumber(1))])),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "name")
      ], nodeOutput(@[nodeVariable("forloop.name")])),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    output = "i-(1..3)"
  )

  testCase(
    "forloop no such attribute",
    "{% for tag in product.tags %}{{ forloop.nosuchthing }}{% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "in"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "tags")
      ], nodeFor("tag", nodeVariable("product.tags"), @[])),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "nosuchthing")
      ], nodeOutput(@[nodeVariable("forloop.nosuchthing")])),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = ""
  )

  testCase(
    "forloop.first",
    "{% for tag in product.tags %}{{ forloop.first }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "in"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "tags")
      ], nodeFor("tag", nodeVariable("product.tags"), @[])),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "first")
      ], nodeOutput(@[nodeVariable("forloop.first")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "true false "
  )

  testCase(
    "forloop.index",
    "{% for tag in product.tags %}{{ forloop.index }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "in"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "tags")
      ], nodeFor("tag", nodeVariable("product.tags"), @[])),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "index")
      ], nodeOutput(@[nodeVariable("forloop.index")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "1 2 "
  )

  testCase(
    "forloop.index0",
    "{% for tag in product.tags %}{{ forloop.index0 }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "in"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "tags")
      ], nodeFor("tag", nodeVariable("product.tags"), @[])),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "index0")
      ], nodeOutput(@[nodeVariable("forloop.index0")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "0 1 "
  )
  
  testCase(
    "forloop.last",
    "{% for tag in product.tags %}{{ forloop.last }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "in"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "tags")
      ], nodeFor("tag", nodeVariable("product.tags"), @[])),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "last")
      ], nodeOutput(@[nodeVariable("forloop.last")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "false true "
  )

  testCase(
    "forloop.rindex",
    "{% for tag in product.tags %}{{ forloop.rindex }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "in"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "tags")
      ], nodeFor("tag", nodeVariable("product.tags"), @[])),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "rindex")
      ], nodeOutput(@[nodeVariable("forloop.rindex")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "2 1 "
  )

  testCase(
    "forloop.rindex0",
    "{% for tag in product.tags %}{{ forloop.rindex0 }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "in"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "tags")
      ], nodeFor("tag", nodeVariable("product.tags"), @[])),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "rindex0")
      ], nodeOutput(@[nodeVariable("forloop.rindex0")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "1 0 "
  )

  testCase(
    "iterate an empty array",
    "{% for item in emptythings.array %}{{ item }}{% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "item"),
        token(TkOperator, "in"),
        token(TkIdentifier, "emptythings"),
        token(TkDot),
        token(TkIdentifier, "array")
      ], nodeFor("item", nodeVariable("emptythings.array"), @[])),
      section(SectionType.Output, @[token(TkIdentifier, "item")], nodeOutput(@[nodeVariable("item")])),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"emptythings": {"array": [], "map": {}, "string": ""}},
    output = ""
  )

  testCase(
    "iterate an empty array with default",
    "{% for item in emptythings.array %}{{ item }}{% else %}foo{% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "item"),
        token(TkOperator, "in"),
        token(TkIdentifier, "emptythings"),
        token(TkDot),
        token(TkIdentifier, "array")
      ], nodeFor("item", nodeVariable("emptythings.array"), @[])),
      section(SectionType.Output, @[token(TkIdentifier, "item")], nodeOutput(@[nodeVariable("item")])),
      section(SectionType.Tag, @[token(TkIdentifier, "else")], nodeElse()),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"emptythings": {"array": [], "map": {}, "string": ""}},
    output = "foo"
  )
  
  testCase(
    "limit",
    "{% for tag in product.tags limit:1 %}{{ tag }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "in"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "tags"),
        token(TkIdentifier, "limit"),
        token(TkColon),
        token(TkNumber, "1")
      ], nodeFor("tag", nodeVariable("product.tags"), @[nodeArgument("limit", nodeNumber(1))])),
      section(SectionType.Output, @[token(TkIdentifier, "tag")], nodeOutput(@[nodeVariable("tag")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "sports "
  )

  testCase(
    "limit is a non-number string",
    "{% for i in (1..4) limit: 'foo' %}{{ i }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "i"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "4"),
        token(TkRightParen),
        token(TkIdentifier, "limit"),
        token(TkColon),
        token(TkString, "foo")
      ], nodeFor("i", nodeRange(nodeNumber(1), nodeNumber(4)), @[nodeArgument("limit", nodeString("foo"))])),
      section(SectionType.Output, @[token(TkIdentifier, "i")], nodeOutput(@[nodeVariable("i")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    error = true
  )

  testCase(
    "limit is a string",
    "{% for i in (1..4) limit: '2' %}{{ i }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "i"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "4"),
        token(TkRightParen),
        token(TkIdentifier, "limit"),
        token(TkColon),
        token(TkString, "2")
      ], nodeFor("i", nodeRange(nodeNumber(1), nodeNumber(4)), @[nodeArgument("limit", nodeNumber(2))])),
      section(SectionType.Output, @[token(TkIdentifier, "i")], nodeOutput(@[nodeVariable("i")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    output = "1 2 "
  )

  testCase(
    "limit is not a string or number",
    "{% for i in (1..4) limit: foo %}{{ i }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "i"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "4"),
        token(TkRightParen),
        token(TkIdentifier, "limit"),
        token(TkColon),
        token(TkIdentifier, "foo")
      ], nodeFor("i", nodeRange(nodeNumber(1), nodeNumber(4)), @[nodeArgument("limit", nodeVariable("foo"))])),
      section(SectionType.Output, @[token(TkIdentifier, "i")], nodeOutput(@[nodeVariable("i")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"foo": [1, 2, 3]},
    error = true
  )

  testCase(
    "lookup a filter from an outer context",
    "{% for tag in product.tags %}{{ tag | upcase }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "in"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "tags")
      ], nodeFor("tag", nodeVariable("product.tags"), @[])),
      section(SectionType.Output, @[
        token(TkIdentifier, "tag"),
        token(TkPipe),
        token(TkIdentifier, "upcase")
      ], nodeOutput(@[nodeFilter("upcase", @[nodeVariable("tag")])])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "SPORTS GARDEN "
  )

  testCase(
    "loop over a string literal",
    "{% for i in 'hello' %}{{ i }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "i"),
        token(TkOperator, "in"),
        token(TkString, "hello")
      ], nodeFor("i", nodeString("hello"), @[])),
      section(SectionType.Output, @[token(TkIdentifier, "i")], nodeOutput(@[nodeVariable("i")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    output = "hello "
  )

  testCase(
    "loop over a string variable",
    "{% for i in foo %}{{ i }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "i"),
        token(TkOperator, "in"),
        token(TkIdentifier, "foo")
      ], nodeFor("i", nodeVariable("foo"), @[])),
      section(SectionType.Output, @[token(TkIdentifier, "i")], nodeOutput(@[nodeVariable("i")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"foo": "hello"},
    output = "hello "
  )

  testCase(
    "loop over an array in reverse",
    "{% for tag in product.tags reversed %}{{ tag }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "in"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "tags"),
        token(TkIdentifier, "reversed")
      ], nodeFor("tag", nodeVariable("product.tags"), @[nodeArgument("reversed", nodeBoolean(true))])),
      section(SectionType.Output, @[token(TkIdentifier, "tag")], nodeOutput(@[nodeVariable("tag")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "garden sports "
  )

  testCase(
    "loop over an existing range object",
    "{% assign foo = (1..3) %}{{ foo | join: '#' }}{% for i in foo %}{{ i }}{% endfor %}{% for i in foo %}{{ i }}{% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "assign"),
        token(TkIdentifier, "foo"),
        token(TkAssign),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "3"),
        token(TkRightParen)
      ], nodeAssign("foo", nodeRange(nodeNumber(1), nodeNumber(3)))),
      section(SectionType.Output, @[
        token(TkIdentifier, "foo"),
        token(TkPipe),
        token(TkIdentifier, "join"),
        token(TkColon),
        token(TkString, "#")
      ], nodeOutput(@[nodeFilter("join", @[nodeVariable("foo"), nodeArgument("", nodeString("#"))])])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "i"),
        token(TkOperator, "in"),
        token(TkIdentifier, "foo")
      ], nodeFor("i", nodeVariable("foo"), @[])),
      section(SectionType.Output, @[token(TkIdentifier, "i")], nodeOutput(@[nodeVariable("i")])),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor()),
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "i"),
        token(TkOperator, "in"),
        token(TkIdentifier, "foo")
      ], nodeFor("i", nodeVariable("foo"), @[])),
      section(SectionType.Output, @[token(TkIdentifier, "i")], nodeOutput(@[nodeVariable("i")])),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    output = "1#2#3123123"
  )

  testCase(
    "loop over nested and chained object from context with trailing identifier",
    "{% for link in linklists[section.settings.menu].links %}{{ link }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "link"),
        token(TkOperator, "in"),
        token(TkIdentifier, "linklists"),
        token(TkLeftBracket),
        token(TkIdentifier, "section"),
        token(TkDot),
        token(TkIdentifier, "settings"),
        token(TkDot),
        token(TkIdentifier, "menu"),
        token(TkRightBracket),
        token(TkDot),
        token(TkIdentifier, "links")
      ], nodeFor("link", nodeVariable("linklists[section.settings.menu].links"), @[])),
      section(SectionType.Output, @[token(TkIdentifier, "link")], nodeOutput(@[nodeVariable("link")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{
      "linklists": {
        "main": {
          "links": ["1", "2"]
        }
      },
      "section": {
        "settings": {
          "menu": "main"
        }
      }
    },
    output = "1 2 "
  )

  testCase(
    "loop over range with float start",
    "{% assign x = (2.4..5) %}{% for i in x %}{{ i }}{% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "assign"),
        token(TkIdentifier, "x"),
        token(TkAssign),
        token(TkLeftParen),
        token(TkNumber, "2.4"),
        token(TkRange),
        token(TkNumber, "5"),
        token(TkRightParen)
      ], nodeAssign("x", nodeRange(nodeNumber(2.4), nodeNumber(5)))),
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "i"),
        token(TkOperator, "in"),
        token(TkIdentifier, "x")
      ], nodeFor("i", nodeVariable("x"), @[])),
      section(SectionType.Output, @[token(TkIdentifier, "i")], nodeOutput(@[nodeVariable("i")])),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    output = "2345"
  )

  testCase(
    "loop over undefined",
    "{% for tag in nosuchthing %}{{ tag }}{% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "in"),
        token(TkIdentifier, "nosuchthing")
      ], nodeFor("tag", nodeVariable("nosuchthing"), @[])),
      section(SectionType.Output, @[token(TkIdentifier, "tag")], nodeOutput(@[nodeVariable("tag")])),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    output = ""
  )

  testCase(
    "nothing to continue from",
    "{% for item in array %}a{{ item }} {% endfor %}{% for item in array offset: continue %}b{{ item }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "item"),
        token(TkOperator, "in"),
        token(TkIdentifier, "array")
      ], nodeFor("item", nodeVariable("array"), @[])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[token(TkIdentifier, "item")], nodeOutput(@[nodeVariable("item")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor()),
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "item"),
        token(TkOperator, "in"),
        token(TkIdentifier, "array"),
        token(TkIdentifier, "offset"),
        token(TkColon),
        token(TkIdentifier, "continue")
      ], nodeFor("item", nodeVariable("array"), @[nodeArgument("offset", nodeContinue())])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[token(TkIdentifier, "item")], nodeOutput(@[nodeVariable("item")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"array": [1, 2, 3, 4, 5, 6]},
    output = "a1 a2 a3 a4 a5 a6 "
  )

  testCase(
    "offset",
    "{% for tag in product.tags offset:1 %}{{ tag }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "in"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "tags"),
        token(TkIdentifier, "offset"),
        token(TkColon),
        token(TkNumber, "1")
      ], nodeFor("tag", nodeVariable("product.tags"), @[nodeArgument("offset", nodeNumber(1))])),
      section(SectionType.Output, @[token(TkIdentifier, "tag")], nodeOutput(@[nodeVariable("tag")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "garden "
  )

  testCase(
    "offset and limit",
    "{% for tag in tags limit: 3 offset: 1 %}{{ tag }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "in"),
        token(TkIdentifier, "tags"),
        token(TkIdentifier, "limit"),
        token(TkColon),
        token(TkNumber, "3"),
        token(TkIdentifier, "offset"),
        token(TkColon),
        token(TkNumber, "1")
      ], nodeFor("tag", nodeVariable("tags"), @[
        nodeArgument("limit", nodeNumber(3)),
        nodeArgument("offset", nodeNumber(1))
      ])),
      section(SectionType.Output, @[token(TkIdentifier, "tag")], nodeOutput(@[nodeVariable("tag")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"tags": ["sports", "garden", "home", "diy", "motoring", "fashion"]},
    output = "garden home diy "
  )

  testCase(
    "offset continue forloop length",
    "{% for item in (1..6) limit: 2 %}a{{ item }} - {{ forloop.length }}, {% endfor %}{% for item in (1..6) offset: continue %}b{{ item }} - {{ forloop.length }}, {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "item"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "6"),
        token(TkRightParen),
        token(TkIdentifier, "limit"),
        token(TkColon),
        token(TkNumber, "2")
      ], nodeFor("item", nodeRange(nodeNumber(1), nodeNumber(6)), @[nodeArgument("limit", nodeNumber(2))])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[token(TkIdentifier, "item")], nodeOutput(@[nodeVariable("item")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "length")
      ], nodeOutput(@[nodeVariable("forloop.length")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor()),
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "item"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "6"),
        token(TkRightParen),
        token(TkIdentifier, "offset"),
        token(TkColon),
        token(TkIdentifier, "continue")
      ], nodeFor("item", nodeRange(nodeNumber(1), nodeNumber(6)), @[nodeArgument("offset", nodeContinue())])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[token(TkIdentifier, "item")], nodeOutput(@[nodeVariable("item")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "length")
      ], nodeOutput(@[nodeVariable("forloop.length")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    output = "a1 - 2, a2 - 2, b3 - 4, b4 - 4, b5 - 4, b6 - 4, "
  )

  testCase(
    "offset continue from a broken loop",
    "{% for item in (1..6) limit: 4 %}{% if item == 3 %}{% break %}{% endif %}a{{ item }} {% endfor %}{% for item in (1..6) offset: continue %}b{{ item }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "item"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "6"),
        token(TkRightParen),
        token(TkIdentifier, "limit"),
        token(TkColon),
        token(TkNumber, "4")
      ], nodeFor("item", nodeRange(nodeNumber(1), nodeNumber(6)), @[nodeArgument("limit", nodeNumber(4))])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "if"),
        token(TkIdentifier, "item"),
        token(TkOperator, "=="),
        token(TkNumber, "3")
      ], nodeIf(nodeComparison("==", nodeVariable("item"), nodeNumber(3)))),
      section(SectionType.Tag, @[token(TkIdentifier, "break")], nodeBreak()),
      section(SectionType.Tag, @[token(TkIdentifier, "endif")], nodeEndIf()),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[token(TkIdentifier, "item")], nodeOutput(@[nodeVariable("item")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor()),
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "item"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "6"),
        token(TkRightParen),
        token(TkIdentifier, "offset"),
        token(TkColon),
        token(TkIdentifier, "continue")
      ], nodeFor("item", nodeRange(nodeNumber(1), nodeNumber(6)), @[nodeArgument("offset", nodeContinue())])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[token(TkIdentifier, "item")], nodeOutput(@[nodeVariable("item")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    output = "a1 a2 b5 b6 "
  )

  testCase(
    "offset continue from a broken loop with preceding limit",
    "{% for item in (1..6) limit: 3 %}a{{ item }} {% endfor %}{% for item in (1..6) %}{% if item == 3 %}{% break %}{% endif %}b{{ item }} {% endfor %}{% for item in (1..6) offset: continue %}c{{ item }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "item"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "6"),
        token(TkRightParen),
        token(TkIdentifier, "limit"),
        token(TkColon),
        token(TkNumber, "3")
      ], nodeFor("item", nodeRange(nodeNumber(1), nodeNumber(6)), @[nodeArgument("limit", nodeNumber(3))])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[token(TkIdentifier, "item")], nodeOutput(@[nodeVariable("item")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor()),
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "item"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "6"),
        token(TkRightParen)
      ], nodeFor("item", nodeRange(nodeNumber(1), nodeNumber(6)), @[])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "if"),
        token(TkIdentifier, "item"),
        token(TkOperator, "=="),
        token(TkNumber, "3")
      ], nodeIf(nodeComparison("==", nodeVariable("item"), nodeNumber(3)))),
      section(SectionType.Tag, @[token(TkIdentifier, "break")], nodeBreak()),
      section(SectionType.Tag, @[token(TkIdentifier, "endif")], nodeEndIf()),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[token(TkIdentifier, "item")], nodeOutput(@[nodeVariable("item")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor()),
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "item"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "6"),
        token(TkRightParen),
        token(TkIdentifier, "offset"),
        token(TkColon),
        token(TkIdentifier, "continue")
      ], nodeFor("item", nodeRange(nodeNumber(1), nodeNumber(6)), @[nodeArgument("offset", nodeContinue())])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[token(TkIdentifier, "item")], nodeOutput(@[nodeVariable("item")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    output = "a1 a2 a3 b1 b2 "
  )

  testCase(
    "offset continue twice with changing limit",
    "{% for item in (1..6) limit: 2 %}a{{ item }} {% endfor %}{% for item in (1..6) limit: 3 offset: continue %}b{{ item }} {% endfor %}{% for item in (1..6) offset: continue %}c{{ item }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "item"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "6"),
        token(TkRightParen),
        token(TkIdentifier, "limit"),
        token(TkColon),
        token(TkNumber, "2")
      ], nodeFor("item", nodeRange(nodeNumber(1), nodeNumber(6)), @[nodeArgument("limit", nodeNumber(2))])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[token(TkIdentifier, "item")], nodeOutput(@[nodeVariable("item")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor()),
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "item"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "6"),
        token(TkRightParen),
        token(TkIdentifier, "limit"),
        token(TkColon),
        token(TkNumber, "3"),
        token(TkIdentifier, "offset"),
        token(TkColon),
        token(TkIdentifier, "continue")
      ], nodeFor("item", nodeRange(nodeNumber(1), nodeNumber(6)), @[
        nodeArgument("limit", nodeNumber(3)),
        nodeArgument("offset", nodeContinue())
      ])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[token(TkIdentifier, "item")], nodeOutput(@[nodeVariable("item")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor()),
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "item"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "6"),
        token(TkRightParen),
        token(TkIdentifier, "offset"),
        token(TkColon),
        token(TkIdentifier, "continue")
      ], nodeFor("item", nodeRange(nodeNumber(1), nodeNumber(6)), @[nodeArgument("offset", nodeContinue())])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[token(TkIdentifier, "item")], nodeOutput(@[nodeVariable("item")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    output = "a1 a2 b3 b4 b5 c6 "
  )

  testCase(
    "offset is a non-number string",
    "{% for i in (1..4) offset: 'foo' %}{{ i }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "i"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "4"),
        token(TkRightParen),
        token(TkIdentifier, "offset"),
        token(TkColon),
        token(TkString, "foo")
      ], nodeFor("i", nodeRange(nodeNumber(1), nodeNumber(4)), @[nodeArgument("offset", nodeString("foo"))])),
      section(SectionType.Output, @[token(TkIdentifier, "i")], nodeOutput(@[nodeVariable("i")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    error = true
  )

  testCase(
    "offset is a string",
    "{% for i in (1..4) offset: '2' %}{{ i }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "i"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "4"),
        token(TkRightParen),
        token(TkIdentifier, "offset"),
        token(TkColon),
        token(TkString, "2")
      ], nodeFor("i", nodeRange(nodeNumber(1), nodeNumber(4)), @[nodeArgument("offset", nodeNumber(2.0))])),
      section(SectionType.Output, @[token(TkIdentifier, "i")], nodeOutput(@[nodeVariable("i")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    output = "3 4 "
  )

  testCase(
    "offset is not a string or number",
    "{% for i in (1..4) offset: foo %}{{ i }} {% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "i"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "4"),
        token(TkRightParen),
        token(TkIdentifier, "offset"),
        token(TkColon),
        token(TkIdentifier, "foo")
      ], nodeFor("i", nodeRange(nodeNumber(1), nodeNumber(4)), @[nodeArgument("offset", nodeVariable("foo"))])),
      section(SectionType.Output, @[token(TkIdentifier, "i")], nodeOutput(@[nodeVariable("i")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    context = %*{"foo": [1, 2, 3]},
    error = true
  )

  testCase(
    "parent's parentloop",
    "{% for i in (1..2) %}{% for j in (1..2) %}{% for k in (1..2) %}i={{ forloop.parentloop.parentloop.index }} j={{ forloop.parentloop.index }} k={{ forloop.index }} {% endfor %}{% endfor %}{% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "i"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "2"),
        token(TkRightParen)
      ], nodeFor("i", nodeRange(nodeNumber(1), nodeNumber(2)), @[])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "j"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "2"),
        token(TkRightParen)
      ], nodeFor("j", nodeRange(nodeNumber(1), nodeNumber(2)), @[])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "k"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "2"),
        token(TkRightParen)
      ], nodeFor("k", nodeRange(nodeNumber(1), nodeNumber(2)), @[])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "parentloop"),
        token(TkDot),
        token(TkIdentifier, "parentloop"),
        token(TkDot),
        token(TkIdentifier, "index")
      ], nodeOutput(@[nodeVariable("forloop.parentloop.parentloop.index")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "parentloop"),
        token(TkDot),
        token(TkIdentifier, "index")
      ], nodeOutput(@[nodeVariable("forloop.parentloop.index")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "index")
      ], nodeOutput(@[nodeVariable("forloop.index")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor()),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor()),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    output = "i=1 j=1 k=1 i=1 j=1 k=2 i=1 j=2 k=1 i=1 j=2 k=2 i=2 j=1 k=1 i=2 j=1 k=2 i=2 j=2 k=1 i=2 j=2 k=2 "
  )

  testCase(
    "parentloop goes out of scope",
    "{% for i in (1..2)%}{% for j in (1..2) %}{{ i }} {{ j }} {% endfor %}{{ forloop.parentloop.index }}{% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "i"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "2"),
        token(TkRightParen)
      ], nodeFor("i", nodeRange(nodeNumber(1), nodeNumber(2)), @[])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "j"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "2"),
        token(TkRightParen)
      ], nodeFor("j", nodeRange(nodeNumber(1), nodeNumber(2)), @[])),
      section(SectionType.Output, @[token(TkIdentifier, "i")], nodeOutput(@[nodeVariable("i")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[token(TkIdentifier, "j")], nodeOutput(@[nodeVariable("j")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor()),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "parentloop"),
        token(TkDot),
        token(TkIdentifier, "index")
      ], nodeOutput(@[nodeVariable("forloop.parentloop.index")])),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    output = "1 1 1 2 2 1 2 2 "
  )

  testCase(
    "parentloop is normally undefined",
    "{% for i in (1..2)%}{{ forloop.parentloop.index }}{% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "i"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "2"),
        token(TkRightParen)
      ], nodeFor("i", nodeRange(nodeNumber(1), nodeNumber(2)), @[])),
      section(SectionType.Output, @[
        token(TkIdentifier, "forloop"),
        token(TkDot),
        token(TkIdentifier, "parentloop"),
        token(TkDot),
        token(TkIdentifier, "index")
      ], nodeOutput(@[nodeVariable("forloop.parentloop.index")])),
      section(SectionType.Tag, @[token(TkIdentifier, "endfor")], nodeEndFor())
    ],
    output = ""
  )

  testCase(
    name = "range loop using identifier",
    liquidTemplate = "{% for i in (0..product.end_range) %}{{ i }} - {{ product.tags[i] }} {% endfor %}",
    expected = @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "i"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "0"),
        token(TkRange),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "end_range"),
        token(TkRightParen)
      ], nodeFor("i", nodeRange(nodeNumber(0), nodeVariable("product.end_range")), @[])),
      section(SectionType.Output, @[
        token(TkIdentifier, "i")
      ], nodeOutput(@[nodeVariable("i")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "tags"),
        token(TkLeftBracket),
        token(TkIdentifier, "i"),
        token(TkRightBracket)
      ], nodeOutput(@[
        nodeIndex(
          nodeDot(nodeIdentifier("product"), "tags"),
          nodeIdentifier("i")
        )
      ])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[
        token(TkIdentifier, "endfor")
      ], nodeEndFor())
    ],
    context = %*{
      "product": {
        "tags": ["sports", "garden"],
        "end_range": 1
      }
    },
    output = "0 - sports 1 - garden "
  )

  testCase(
    name = "range start and stop are the same",
    liquidTemplate = "{% for i in (1..1) %}{{ i }} {% endfor %}",
    expected = @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "i"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "1"),
        token(TkRightParen)
      ], nodeFor("i", nodeRange(nodeNumber(1), nodeNumber(1)), @[])),
      section(SectionType.Output, @[
        token(TkIdentifier, "i")
      ], nodeOutput(@[nodeVariable("i")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[
        token(TkIdentifier, "endfor")
      ], nodeEndFor())
    ],
    output = "1 "
  )

  testCase(
    name = "range start and stop are zero",
    liquidTemplate = "{% for i in (0..0) %}{{ i }} {% endfor %}",
    expected = @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "i"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "0"),
        token(TkRange),
        token(TkNumber, "0"),
        token(TkRightParen)
      ], nodeFor("i", nodeRange(nodeNumber(0), nodeNumber(0)), @[])),
      section(SectionType.Output, @[
        token(TkIdentifier, "i")
      ], nodeOutput(@[nodeVariable("i")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[
        token(TkIdentifier, "endfor")
      ], nodeEndFor())
    ],
    output = "0 "
  )

  testCase(
    name = "share outer scope",
    liquidTemplate = "{% assign foo = 'hello' %}{% for x in (1..3) %}{% assign foo = x %}{% endfor %}{{ foo }}",
    expected = @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "assign"),
        token(TkIdentifier, "foo"),
        token(TkAssign),
        token(TkString, "hello")
      ], nodeAssign("foo", nodeString("hello"))),
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "x"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "3"),
        token(TkRightParen)
      ], nodeFor("x", nodeRange(nodeNumber(1), nodeNumber(3)), @[])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "assign"),
        token(TkIdentifier, "foo"),
        token(TkAssign),
        token(TkIdentifier, "x")
      ], nodeAssign("foo", nodeVariable("x"))),
      section(SectionType.Tag, @[
        token(TkIdentifier, "endfor")
      ], nodeEndFor()),
      section(SectionType.Output, @[
        token(TkIdentifier, "foo")
      ], nodeOutput(@[nodeVariable("foo")]))
    ],
    output = "3"
  )
  
  testCase(
    name = "simple array loop",
    liquidTemplate = "{% for tag in product.tags %}{{ tag }} {% endfor %}",
    expected = @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "tag"),
        token(TkOperator, "in"),
        token(TkIdentifier, "product"),
        token(TkDot),
        token(TkIdentifier, "tags")
      ], nodeFor("tag", nodeVariable("product.tags"), @[])),
      section(SectionType.Output, @[
        token(TkIdentifier, "tag")
      ], nodeOutput(@[nodeVariable("tag")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[
        token(TkIdentifier, "endfor")
      ], nodeEndFor())
    ],
    context = %*{
      "product": {
        "tags": ["sports", "garden"]
      }
    },
    output = "sports garden "
  )

  testCase(
    name = "simple hash loop",
    liquidTemplate = "{% for c in collection %}{{ c[0] }} {{ c[1] }} {% endfor %}",
    expected = @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "c"),
        token(TkOperator, "in"),
        token(TkIdentifier, "collection")
      ], nodeFor("c", nodeVariable("collection"), @[])),
      section(SectionType.Output, @[
        token(TkIdentifier, "c"),
        token(TkLeftBracket),
        token(TkNumber, "0"),
        token(TkRightBracket)
      ], nodeOutput(@[nodeVariable("c[0]")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkIdentifier, "c"),
        token(TkLeftBracket),
        token(TkNumber, "1"),
        token(TkRightBracket)
      ], nodeOutput(@[nodeVariable("c[1]")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[
        token(TkIdentifier, "endfor")
      ], nodeEndFor())
    ],
    context = %*{
      "collection": {
        "title": "foo",
        "description": "bar"
      }
    },
    output = "title foo description bar "
  )

  testCase(
    name = "simple range loop",
    liquidTemplate = "{% for i in (0..3) %}{{ i }} {% endfor %}",
    expected = @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "i"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "0"),
        token(TkRange),
        token(TkNumber, "3"),
        token(TkRightParen)
      ], nodeFor("i", nodeRange(nodeNumber(0), nodeNumber(3)), @[])),
      section(SectionType.Output, @[
        token(TkIdentifier, "i")
      ], nodeOutput(@[nodeVariable("i")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[
        token(TkIdentifier, "endfor")
      ], nodeEndFor())
    ],
    output = "0 1 2 3 "
  )

  testCase(
    name = "some comma separated arguments",
    liquidTemplate = "{% for i in (1..6) limit: 4, offset: 2, %}{{ i }} {% endfor %}",
    expected = @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "for"),
        token(TkIdentifier, "i"),
        token(TkOperator, "in"),
        token(TkLeftParen),
        token(TkNumber, "1"),
        token(TkRange),
        token(TkNumber, "6"),
        token(TkRightParen),
        token(TkIdentifier, "limit"),
        token(TkColon),
        token(TkNumber, "4"),
        token(TkComma),
        token(TkIdentifier, "offset"),
        token(TkColon),
        token(TkNumber, "2"),
        token(TkComma)
      ], nodeFor("i", nodeRange(nodeNumber(1), nodeNumber(6)), @[
        nodeArgument("limit", nodeNumber(4)),
        nodeArgument("offset", nodeNumber(2))
      ])),
      section(SectionType.Output, @[
        token(TkIdentifier, "i")
      ], nodeOutput(@[nodeVariable("i")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[
        token(TkIdentifier, "endfor")
      ], nodeEndFor())
    ],
    output = "3 4 5 6 "
  )
