

suite "cycle tag":
  testCase(
    "changing variable name",
    "{% cycle a: 1, 2, 3 %}{% assign a = 'bar' %}{% cycle a: 1, 2, 3 %}{% cycle a: 1, 2, 3 %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkIdentifier, "a"),
        token(TkColon),
        token(TkNumber, "1"),
        token(TkComma),
        token(TkNumber, "2"),
        token(TkComma),
        token(TkNumber, "3")
      ], nodeCycle("a", @[nodeNumber(1), nodeNumber(2), nodeNumber(3)])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "assign"),
        token(TkIdentifier, "a"),
        token(TkAssign),
        token(TkString, "bar")
      ], nodeAssign("a", nodeString("bar"))),
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkIdentifier, "a"),
        token(TkColon),
        token(TkNumber, "1"),
        token(TkComma),
        token(TkNumber, "2"),
        token(TkComma),
        token(TkNumber, "3")
      ], nodeCycle("a", @[nodeNumber(1), nodeNumber(2), nodeNumber(3)])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkIdentifier, "a"),
        token(TkColon),
        token(TkNumber, "1"),
        token(TkComma),
        token(TkNumber, "2"),
        token(TkComma),
        token(TkNumber, "3")
      ], nodeCycle("a", @[nodeNumber(1), nodeNumber(2), nodeNumber(3)]))
    ],
    context = %*{"a": "foo"},
    output = "112"
  )

  testCase(
    "different items",
    "{% cycle '1', '2', '3' %}{% cycle '1', '2' %}{% cycle '1', '2', '3' %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkString, "1"),
        token(TkComma),
        token(TkString, "2"),
        token(TkComma),
        token(TkString, "3")
      ], nodeCycle(@[nodeString("1"), nodeString("2"), nodeString("3")])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkString, "1"),
        token(TkComma),
        token(TkString, "2")
      ], nodeCycle(@[nodeString("1"), nodeString("2")])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkString, "1"),
        token(TkComma),
        token(TkString, "2"),
        token(TkComma),
        token(TkString, "3")
      ], nodeCycle(@[nodeString("1"), nodeString("2"), nodeString("3")]))
    ],
    output = "112"
  )

  testCase(
    "integers",
    "{% cycle 1, 2, 3 %}{% cycle 1, 2, 3 %}{% cycle 1, 2, 3 %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkNumber, "1"),
        token(TkComma),
        token(TkNumber, "2"),
        token(TkComma),
        token(TkNumber, "3")
      ], nodeCycle( @[nodeNumber(1), nodeNumber(2), nodeNumber(3)])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkNumber, "1"),
        token(TkComma),
        token(TkNumber, "2"),
        token(TkComma),
        token(TkNumber, "3")
      ], nodeCycle( @[nodeNumber(1), nodeNumber(2), nodeNumber(3)])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkNumber, "1"),
        token(TkComma),
        token(TkNumber, "2"),
        token(TkComma),
        token(TkNumber, "3")
      ], nodeCycle( @[nodeNumber(1), nodeNumber(2), nodeNumber(3)]))
    ],
    output = "123"
  )

  testCase(
    "multiple undefined variable names",
    "{% cycle a: 1, 2, 3 %}{% cycle b: 1, 2, 3 %}{% cycle a: 1, 2, 3 %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkIdentifier, "a"),
        token(TkColon),
        token(TkNumber, "1"),
        token(TkComma),
        token(TkNumber, "2"),
        token(TkComma),
        token(TkNumber, "3")
      ], nodeCycle("a", @[nodeNumber(1), nodeNumber(2), nodeNumber(3)])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkIdentifier, "b"),
        token(TkColon),
        token(TkNumber, "1"),
        token(TkComma),
        token(TkNumber, "2"),
        token(TkComma),
        token(TkNumber, "3")
      ], nodeCycle("b", @[nodeNumber(1), nodeNumber(2), nodeNumber(3)])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkIdentifier, "a"),
        token(TkColon),
        token(TkNumber, "1"),
        token(TkComma),
        token(TkNumber, "2"),
        token(TkComma),
        token(TkNumber, "3")
      ], nodeCycle("a", @[nodeNumber(1), nodeNumber(2), nodeNumber(3)]))
    ],
    output = "123"
  )

  testCase(
    "named with different items",
    "{% cycle 'a': 1, 2, 3 %}{% cycle 'a': 7, 8, 9 %}{% cycle 'a': 1, 2, 3 %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkString, "a"),
        token(TkColon),
        token(TkNumber, "1"),
        token(TkComma),
        token(TkNumber, "2"),
        token(TkComma),
        token(TkNumber, "3")
      ], nodeCycle("a", @[nodeNumber(1), nodeNumber(2), nodeNumber(3)])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkString, "a"),
        token(TkColon),
        token(TkNumber, "7"),
        token(TkComma),
        token(TkNumber, "8"),
        token(TkComma),
        token(TkNumber, "9")
      ], nodeCycle("a", @[nodeNumber(7), nodeNumber(8), nodeNumber(9)])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkString, "a"),
        token(TkColon),
        token(TkNumber, "1"),
        token(TkComma),
        token(TkNumber, "2"),
        token(TkComma),
        token(TkNumber, "3")
      ], nodeCycle("a", @[nodeNumber(1), nodeNumber(2), nodeNumber(3)]))
    ],
    output = "183"
  )

  testCase(
    "named with different number of arguments",
    "{% cycle a: '1', '2' %}{% cycle a: '1', '2', '3' %}{% cycle a: '1' %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkIdentifier, "a"),
        token(TkColon),
        token(TkString, "1"),
        token(TkComma),
        token(TkString, "2")
      ], nodeCycle("a", @[nodeString("1"), nodeString("2")])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkIdentifier, "a"),
        token(TkColon),
        token(TkString, "1"),
        token(TkComma),
        token(TkString, "2"),
        token(TkComma),
        token(TkString, "3")
      ], nodeCycle("a", @[nodeString("1"), nodeString("2"), nodeString("3")])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkIdentifier, "a"),
        token(TkColon),
        token(TkString, "1")
      ], nodeCycle("a", @[nodeString("1")]))
    ],
    output = "12"
  )

  testCase(
    "named with growing number of arguments",
    "{% cycle a: '1' %}{% cycle a: '1', '2' %}{% cycle a: '1', '2', '3' %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkIdentifier, "a"),
        token(TkColon),
        token(TkString, "1")
      ], nodeCycle("a", @[nodeString("1")])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkIdentifier, "a"),
        token(TkColon),
        token(TkString, "1"),
        token(TkComma),
        token(TkString, "2")
      ], nodeCycle("a", @[nodeString("1"), nodeString("2")])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkIdentifier, "a"),
        token(TkColon),
        token(TkString, "1"),
        token(TkComma),
        token(TkString, "2"),
        token(TkComma),
        token(TkString, "3")
      ], nodeCycle("a", @[nodeString("1"), nodeString("2"), nodeString("3")]))
    ],
    output = "112"
  )

  testCase(
    "named with shrinking number of arguments",
    "{% cycle a: '1', '2', '3' %}{% cycle a: '1', '2' %}{% cycle a: '1' %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkIdentifier, "a"),
        token(TkColon),
        token(TkString, "1"),
        token(TkComma),
        token(TkString, "2"),
        token(TkComma),
        token(TkString, "3")
      ], nodeCycle("a", @[nodeString("1"), nodeString("2"), nodeString("3")])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkIdentifier, "a"),
        token(TkColon),
        token(TkString, "1"),
        token(TkComma),
        token(TkString, "2")
      ], nodeCycle("a", @[nodeString("1"), nodeString("2")])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkIdentifier, "a"),
        token(TkColon),
        token(TkString, "1")
      ], nodeCycle("a", @[nodeString("1")]))
    ],
    output = "121"
  )

  testCase(
    "no identifier",
    "{% cycle 'some', 'other' %}{% cycle 'some', 'other' %}{% cycle 'some', 'other' %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkString, "some"),
        token(TkComma),
        token(TkString, "other")
      ], nodeCycle( @[nodeString("some"), nodeString("other")])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkString, "some"),
        token(TkComma),
        token(TkString, "other")
      ], nodeCycle( @[nodeString("some"), nodeString("other")])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkString, "some"),
        token(TkComma),
        token(TkString, "other")
      ], nodeCycle( @[nodeString("some"), nodeString("other")]))
    ],
    output = "someothersome"
  )

  testCase(
    "undefined variable names mixed with no name",
    "{% cycle a: 1, 2, 3 %}{% cycle b: 1, 2, 3 %}{% cycle 1, 2, 3 %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkIdentifier, "a"),
        token(TkColon),
        token(TkNumber, "1"),
        token(TkComma),
        token(TkNumber, "2"),
        token(TkComma),
        token(TkNumber, "3")
      ], nodeCycle("a", @[nodeNumber(1), nodeNumber(2), nodeNumber(3)])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkIdentifier, "b"),
        token(TkColon),
        token(TkNumber, "1"),
        token(TkComma),
        token(TkNumber, "2"),
        token(TkComma),
        token(TkNumber, "3")
      ], nodeCycle("b", @[nodeNumber(1), nodeNumber(2), nodeNumber(3)])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkNumber, "1"),
        token(TkComma),
        token(TkNumber, "2"),
        token(TkComma),
        token(TkNumber, "3")
      ], nodeCycle( @[nodeNumber(1), nodeNumber(2), nodeNumber(3)]))
    ],
    output = "121"
  )

  testCase(
    "variable name",
    "{% cycle a: 1, 2, 3 %}{% cycle a: 1, 2, 3 %}{% cycle a: 1, 2, 3 %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkIdentifier, "a"),
        token(TkColon),
        token(TkNumber, "1"),
        token(TkComma),
        token(TkNumber, "2"),
        token(TkComma),
        token(TkNumber, "3")
      ], nodeCycle("a", @[nodeNumber(1), nodeNumber(2), nodeNumber(3)])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkIdentifier, "a"),
        token(TkColon),
        token(TkNumber, "1"),
        token(TkComma),
        token(TkNumber, "2"),
        token(TkComma),
        token(TkNumber, "3")
      ], nodeCycle("a", @[nodeNumber(1), nodeNumber(2), nodeNumber(3)])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkIdentifier, "a"),
        token(TkColon),
        token(TkNumber, "1"),
        token(TkComma),
        token(TkNumber, "2"),
        token(TkComma),
        token(TkNumber, "3")
      ], nodeCycle("a", @[nodeNumber(1), nodeNumber(2), nodeNumber(3)]))
    ],
    context = %*{"a": "foo"},
    output = "123"
  )

  testCase(
    "with identifier",
    "{% cycle 'foo': 'some', 'other' %}{% cycle 'some', 'other' %}{% cycle 'foo': 'some', 'other' %}",
    @[
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkString, "foo"),
        token(TkColon),
        token(TkString, "some"),
        token(TkComma),
        token(TkString, "other")
      ], nodeCycle("foo", @[nodeString("some"), nodeString("other")])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkString, "some"),
        token(TkComma),
        token(TkString, "other")
      ], nodeCycle( @[nodeString("some"), nodeString("other")])),
      section(SectionType.Tag, @[
        token(TkIdentifier, "cycle"),
        token(TkString, "foo"),
        token(TkColon),
        token(TkString, "some"),
        token(TkComma),
        token(TkString, "other")
      ], nodeCycle("foo", @[nodeString("some"), nodeString("other")]))
    ],
    output = "someothersome"
  )
