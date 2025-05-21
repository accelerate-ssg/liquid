import helpers

suite "identifiers":
  testCase(
    "ascii lowercase",
    "{% assign foo = 'hello' %}{{ foo }} {{ bar }}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "assign"),
        token(TkIdentifier, "foo"),
        token(TkAssign),
        token(TkString, "hello")
      ], nodeAssign("foo", nodeString("hello"))),
      section(SectionType.Output, @[
        token(TkIdentifier, "foo")
      ], nodeOutput(@[nodeVariable("foo")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkIdentifier, "bar")
      ], nodeOutput(@[nodeVariable("bar")]))
    ],
    context = %*{"bar": "goodbye"},
    output = "hello goodbye",
    strict = true
  )

  testCase(
    "ascii uppercase",
    "{% assign FOO = 'hello' %}{{ FOO }} {{ BAR }}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "assign"),
        token(TkIdentifier, "FOO"),
        token(TkAssign),
        token(TkString, "hello")
      ], nodeAssign("FOO", nodeString("hello"))),
      section(SectionType.Output, @[
        token(TkIdentifier, "FOO")
      ], nodeOutput(@[nodeVariable("FOO")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkIdentifier, "BAR")
      ], nodeOutput(@[nodeVariable("BAR")]))
    ],
    context = %*{"BAR": "goodbye"},
    output = "hello goodbye",
    strict = true
  )

  testCase(
    "at sign",
    "{{ @foo }}",
    @[
      section(SectionType.Output, @[
      ], nodeOutput(@[]))
    ],
    context = %*{"@foo": "hello"},
    error = true,
    strict = true
  )

  testCase(
    "capture ascii lowercase",
    "{% capture foo %}hello{% endcapture %}{{ foo }}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "capture"),
        token(TkIdentifier, "foo")
      ], nodeCapture("foo")),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[
        token(TkKeyword, "endcapture")
      ], nodeEndCapture()),
      section(SectionType.Output, @[
        token(TkIdentifier, "foo")
      ], nodeOutput(@[nodeVariable("foo")]))
    ],
    output = "hello",
    strict = true
  )

  testCase(
    "capture ascii uppercase",
    "{% capture FOO %}hello{% endcapture %}{{ FOO }}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "capture"),
        token(TkIdentifier, "FOO")
      ], nodeCapture("FOO")),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[
        token(TkKeyword, "endcapture")
      ], nodeEndCapture()),
      section(SectionType.Output, @[
        token(TkIdentifier, "FOO")
      ], nodeOutput(@[nodeVariable("FOO")]))
    ],
    output = "hello",
    strict = true
  )

  testCase(
    "capture digits",
    "{% capture foo1 %}hello{% endcapture %}{{ foo1 }}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "capture"),
        token(TkIdentifier, "foo1")
      ], nodeCapture("foo1")),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[
        token(TkKeyword, "endcapture")
      ], nodeEndCapture()),
      section(SectionType.Output, @[
        token(TkIdentifier, "foo1")
      ], nodeOutput(@[nodeVariable("foo1")]))
    ],
    output = "hello",
    strict = true
  )

  testCase(
    "capture hyphens",
    "{% capture foo-a %}hello {{ bar-b }}{% endcapture %}{{ foo-a }}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "capture"),
        token(TkIdentifier, "foo-a")
      ], nodeCapture("foo-a")),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkIdentifier, "bar-b")
      ], nodeOutput(@[nodeVariable("bar-b")])),
      section(SectionType.Tag, @[
        token(TkKeyword, "endcapture")
      ], nodeEndCapture()),
      section(SectionType.Output, @[
        token(TkIdentifier, "foo-a")
      ], nodeOutput(@[nodeVariable("foo-a")]))
    ],
    context = %*{"bar-b": "goodbye"},
    output = "hello goodbye",
    strict = true
  )

  testCase(
    "capture leading hyphen",
    "{% capture -foo %}hello {{ -bar }}{% endcapture %}{{ -foo }}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "capture"),
        token(TkOperator, "-"),
        token(TkIdentifier, "foo")
      ], nodeCapture("-foo")),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkOperator, "-"),
        token(TkIdentifier, "bar")
      ], nodeOutput(@[nodeVariable("-bar")])),
      section(SectionType.Tag, @[
        token(TkKeyword, "endcapture")
      ], nodeEndCapture()),
      section(SectionType.Output, @[
        token(TkOperator, "-"),
        token(TkIdentifier, "foo")
      ], nodeOutput(@[nodeVariable("-foo")]))
    ],
    context = %*{"-bar": "goodbye"},
    error = true,
    strict = true
  )

  testCase(
    "capture leading underscore",
    "{% capture _foo %}hello {{ _bar }}{% endcapture %}{{ _foo }}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "capture"),
        token(TkIdentifier, "_foo")
      ], nodeCapture("_foo")),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkIdentifier, "_bar")
      ], nodeOutput(@[nodeVariable("_bar")])),
      section(SectionType.Tag, @[
        token(TkKeyword, "endcapture")
      ], nodeEndCapture()),
      section(SectionType.Output, @[
        token(TkIdentifier, "_foo")
      ], nodeOutput(@[nodeVariable("_foo")]))
    ],
    context = %*{"_bar": "goodbye"},
    output = "hello goodbye",
    strict = true
  )

  testCase(
    "capture only digits",
    "{% capture 123 %}hello{% endcapture %}{{ 123 }}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "capture"),
        token(TkNumber, "123")
      ], nodeCapture("123")),
      section(SectionType.Text, @[], nil),
      section(SectionType.Tag, @[
        token(TkKeyword, "endcapture")
      ], nodeEndCapture()),
      section(SectionType.Output, @[
        token(TkNumber, "123")
      ], nodeOutput(@[nodeNumber(123)]))
    ],
    output = "123",
    strict = true
  )

  testCase(
    "capture only underscore",
    "{% capture _ %}hello {{ __ }}{% endcapture %}{{ _ }}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "capture"),
        token(TkIdentifier, "_")
      ], nodeCapture("_")),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkIdentifier, "__")
      ], nodeOutput(@[nodeVariable("__")])),
      section(SectionType.Tag, @[
        token(TkKeyword, "endcapture")
      ], nodeEndCapture()),
      section(SectionType.Output, @[
        token(TkIdentifier, "_")
      ], nodeOutput(@[nodeVariable("_")]))
    ],
    context = %*{"__": "goodbye"},
    output = "hello goodbye",
    strict = true
  )

  testCase(
    "capture underscore",
    "{% capture foo_a %}hello {{ bar_b }}{% endcapture %}{{ foo_a }}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "capture"),
        token(TkIdentifier, "foo_a")
      ], nodeCapture("foo_a")),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkIdentifier, "bar_b")
      ], nodeOutput(@[nodeVariable("bar_b")])),
      section(SectionType.Tag, @[
        token(TkKeyword, "endcapture")
      ], nodeEndCapture()),
      section(SectionType.Output, @[
        token(TkIdentifier, "foo_a")
      ], nodeOutput(@[nodeVariable("foo_a")]))
    ],
    context = %*{"bar_b": "goodbye"},
    output = "hello goodbye",
    strict = true
  )

  testCase(
    "decrement with a hyphen",
    "{% decrement f-oo %}{% decrement f-oo %}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "decrement"),
        token(TkIdentifier, "f-oo")
      ], nodeDecrement("f-oo")),
      section(SectionType.Tag, @[
        token(TkKeyword, "decrement"),
        token(TkIdentifier, "f-oo")
      ], nodeDecrement("f-oo"))
    ],
    output = "-1-2",
    strict = true
  )

  testCase(
    "digits",
    "{% assign foo1 = 'hello' %}{{ foo1 }} {{ bar2 }}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "assign"),
        token(TkIdentifier, "foo1"),
        token(TkAssign),
        token(TkString, "hello")
      ], nodeAssign("foo1", nodeString("hello"))),
      section(SectionType.Output, @[
        token(TkIdentifier, "foo1")
      ], nodeOutput(@[nodeVariable("foo1")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkIdentifier, "bar2")
      ], nodeOutput(@[nodeVariable("bar2")]))
    ],
    context = %*{"bar2": "goodbye"},
    output = "hello goodbye",
    strict = true
  )

  testCase(
    "hyphen in for loop target",
    "{% for x in f-oo %}{{ x }}{% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "for"),
        token(TkIdentifier, "x"),
        token(TkKeyword, "in"),
        token(TkIdentifier, "f-oo")
      ], nodeFor("x", nodeVariable("f-oo"), @[])),
      section(SectionType.Output, @[
        token(TkIdentifier, "x")
      ], nodeOutput(@[nodeVariable("x")])),
      section(SectionType.Tag, @[
        token(TkKeyword, "endfor")
      ], nodeEndFor())
    ],
    context = %*{"f-oo": [1, 2, 3]},
    output = "123",
    strict = true
  )

  testCase(
    "hyphen in for loop variable",
    "{% for x-y in foo %}{{ x-y }}{% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "for"),
        token(TkIdentifier, "x-y"),
        token(TkKeyword, "in"),
        token(TkIdentifier, "foo")
      ], nodeFor("x-y", nodeVariable("foo"), @[])),
      section(SectionType.Output, @[
        token(TkIdentifier, "x-y")
      ], nodeOutput(@[nodeVariable("x-y")])),
      section(SectionType.Tag, @[
        token(TkKeyword, "endfor")
      ], nodeEndFor())
    ],
    context = %*{"foo": [1, 2, 3]},
    output = "123",
    strict = true
  )

  testCase(
    "hyphens",
    "{% assign foo-a = 'hello' %}{{ foo-a }} {{ bar-b }}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "assign"),
        token(TkIdentifier, "foo-a"),
        token(TkAssign),
        token(TkString, "hello")
      ], nodeAssign("foo-a", nodeString("hello"))),
      section(SectionType.Output, @[
        token(TkIdentifier, "foo-a")
      ], nodeOutput(@[nodeVariable("foo-a")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkIdentifier, "bar-b")
      ], nodeOutput(@[nodeVariable("bar-b")]))
    ],
    context = %*{"bar-b": "goodbye"},
    output = "hello goodbye",
    strict = true
  )

  testCase(
    "increment with a hyphen",
    "{% increment f-oo %}{% increment f-oo %}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "increment"),
        token(TkIdentifier, "f-oo")
      ], nodeIncrement("f-oo")),
      section(SectionType.Tag, @[
        token(TkKeyword, "increment"),
        token(TkIdentifier, "f-oo")
      ], nodeIncrement("f-oo"))
    ],
    output = "01",
    strict = true
  )

  testCase(
    "leading hyphen",
    "{% assign -foo = 'hello' %}{{ -foo }} {{ -bar }}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "assign"),
        token(TkOperator, "-"),
        token(TkIdentifier, "foo"),
        token(TkAssign),
        token(TkString, "hello")
      ], nodeAssign("-foo", nodeString("hello"))),
      section(SectionType.Output, @[
        token(TkOperator, "-"),
        token(TkIdentifier, "foo")
      ], nodeOutput(@[nodeVariable("-foo")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkOperator, "-"),
        token(TkIdentifier, "bar")
      ], nodeOutput(@[nodeVariable("-bar")]))
    ],
    context = %*{"-bar": "goodbye"},
    error = true,
    strict = true
  )

  testCase(
    "leading hyphen in for loop target",
    "{% for x in -foo %}{{ x }}{% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "for"),
        token(TkIdentifier, "x"),
        token(TkKeyword, "in"),
        token(TkOperator, "-"),
        token(TkIdentifier, "foo")
      ], nodeFor("x", nodeVariable("-foo"), @[])),
      section(SectionType.Output, @[
        token(TkIdentifier, "x")
      ], nodeOutput(@[nodeVariable("x")])),
      section(SectionType.Tag, @[
        token(TkKeyword, "endfor")
      ], nodeEndFor())
    ],
    context = %*{"-foo": [1, 2, 3]},
    error = true,
    strict = true
  )

  testCase(
    "leading underscore",
    "{% assign _foo = 'hello' %}{{ _foo }} {{ _bar }}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "assign"),
        token(TkIdentifier, "_foo"),
        token(TkAssign),
        token(TkString, "hello")
      ], nodeAssign("_foo", nodeString("hello"))),
      section(SectionType.Output, @[
        token(TkIdentifier, "_foo")
      ], nodeOutput(@[nodeVariable("_foo")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkIdentifier, "_bar")
      ], nodeOutput(@[nodeVariable("_bar")]))
    ],
    context = %*{"_bar": "goodbye"},
    output = "hello goodbye",
    strict = true
  )

  testCase(
    "only digits",
    "{% assign 123 = 'hello' %}{{ 123 }} {{ 456 }}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "assign"),
        token(TkNumber, "123"),
        token(TkAssign),
        token(TkString, "hello")
      ], nodeAssign("123", nodeString("hello"))),
      section(SectionType.Output, @[
        token(TkNumber, "123")
      ], nodeOutput(@[nodeNumber(123)])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkNumber, "456")
      ], nodeOutput(@[nodeNumber(456)]))
    ],
    context = %*{"456": "goodbye"},
    output = "123 456",
    strict = true
  )

  testCase(
    "only underscore",
    "{% assign _ = 'hello' %}{{ _ }} {{ __ }}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "assign"),
        token(TkIdentifier, "_"),
        token(TkAssign),
        token(TkString, "hello")
      ], nodeAssign("_", nodeString("hello"))),
      section(SectionType.Output, @[
        token(TkIdentifier, "_")
      ], nodeOutput(@[nodeVariable("_")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkIdentifier, "__")
      ], nodeOutput(@[nodeVariable("__")]))
    ],
    context = %*{"__": "goodbye"},
    output = "hello goodbye",
    strict = true
  )

  testCase(
    "trailing question mark assign",
    "{% assign foo? = 'hello' %}{{ foo? }}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "assign"),
        token(TkIdentifier, "foo?"),
        token(TkAssign),
        token(TkString, "hello")
      ], nodeAssign("foo?", nodeString("hello"))),
      section(SectionType.Output, @[
        token(TkIdentifier, "foo?")
      ], nodeOutput(@[nodeVariable("foo?")]))
    ],
    error = true,
    strict = true
  )

  testCase(
    "trailing question mark in for loop target",
    "{% for x in foo? %}{{ x }}{% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "for"),
        token(TkIdentifier, "x"),
        token(TkKeyword, "in"),
        token(TkIdentifier, "foo?")
      ], nodeFor("x", nodeVariable("foo?"), @[])),
      section(SectionType.Output, @[
        token(TkIdentifier, "x")
      ], nodeOutput(@[nodeVariable("x")])),
      section(SectionType.Tag, @[
        token(TkKeyword, "endfor")
      ], nodeEndFor())
    ],
    context = %*{"foo?": [1, 2, 3]},
    output = "123",
    strict = true
  )

  testCase(
    "trailing question mark in for loop variable",
    "{% for x? in foo %}{{ x? }}{% endfor %}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "for"),
        token(TkIdentifier, "x?"),
        token(TkKeyword, "in"),
        token(TkIdentifier, "foo")
      ], nodeFor("x?", nodeVariable("foo"), @[])),
      section(SectionType.Output, @[
        token(TkIdentifier, "x?")
      ], nodeOutput(@[nodeVariable("x?")])),
      section(SectionType.Tag, @[
        token(TkKeyword, "endfor")
      ], nodeEndFor())
    ],
    context = %*{"foo": [1, 2, 3]},
    output = "123",
    strict = true
  )

  testCase(
    "trailing question mark output",
    "{{ bar? }}",
    @[
      section(SectionType.Output, @[
        token(TkIdentifier, "bar?")
      ], nodeOutput(@[nodeVariable("bar?")]))
    ],
    context = %*{"bar?": "goodbye"},
    output = "goodbye",
    strict = true
  )

  testCase(
    "underscore",
    "{% assign foo_a = 'hello' %}{{ foo_a }} {{ bar_b }}",
    @[
      section(SectionType.Tag, @[
        token(TkKeyword, "assign"),
        token(TkIdentifier, "foo_a"),
        token(TkAssign),
        token(TkString, "hello")
      ], nodeAssign("foo_a", nodeString("hello"))),
      section(SectionType.Output, @[
        token(TkIdentifier, "foo_a")
      ], nodeOutput(@[nodeVariable("foo_a")])),
      section(SectionType.Text, @[], nil),
      section(SectionType.Output, @[
        token(TkIdentifier, "bar_b")
      ], nodeOutput(@[nodeVariable("bar_b")]))
    ],
    context = %*{"bar_b": "goodbye"},
    output = "hello goodbye",
    strict = true
  )
