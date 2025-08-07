suite "whitespace control":
  testCase(
    "don't suppress whitespace only blocks containing echo",
    "!{% if true %}\n\n{% assign bar = 'foo' %}\n    {% echo '' %}\n\n    {% assign foo = 'bar' %}\n\n\n\n{% endif %}!",
    @[
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "if"), token(TkBoolean, "true")],
        nodeIf(nodeBoolean(true))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "assign"), token(TkIdentifier, "bar"), token(TkAssign), token(TkString, "foo")],
        nodeAssign("bar", nodeString("foo"))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "echo"), token(TkString, "")],
        nodeEcho(@[nodeString("")])
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "assign"), token(TkIdentifier, "foo"), token(TkAssign), token(TkString, "bar")],
        nodeAssign("foo", nodeString("bar"))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "endif")],
        nodeEndIf()
      ),
      section(SectionType.Text, @[], nil)
    ],
    output = "!\n\n\n    \n\n    \n\n\n\n!"
  )

  testCase(
    "don't suppress whitespace only blocks containing output",
    "!{% if true %}\n\n{% assign bar = 'foo' %}\n    {{ '' }}\n\n    {% assign foo = 'bar' %}\n\n\n\n{% endif %}!",
    @[
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "if"), token(TkBoolean, "true")],
        nodeIf(nodeBoolean(true))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "assign"), token(TkIdentifier, "bar"), token(TkAssign), token(TkString, "foo")],
        nodeAssign("bar", nodeString("foo"))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Output,
        @[token(TkString, "")],
        nodeOutput(@[nodeString("")])
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "assign"), token(TkIdentifier, "foo"), token(TkAssign), token(TkString, "bar")],
        nodeAssign("foo", nodeString("bar"))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "endif")],
        nodeEndIf()
      ),
      section(SectionType.Text, @[], nil)
    ],
    output = "!\n\n\n    \n\n    \n\n\n\n!"
  )

  testCase(
    "don't suppress whitespace only blocks containing output in nested block",
    "!{% if 1 %}\n\n{% assign bar = 'foo' %}\n{% if 2 %}\n    {{ '' }}\n\n    {% assign foo = 'bar' %}\n\n{% endif %}\n\n\n{% endif %}!",
    @[
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "if"), token(TkNumber, "1")],
        nodeIf(nodeNumber(1))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "assign"), token(TkIdentifier, "bar"), token(TkAssign), token(TkString, "foo")],
        nodeAssign("bar", nodeString("foo"))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "if"), token(TkNumber, "2")],
        nodeIf(nodeNumber(2))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Output,
        @[token(TkString, "")],
        nodeOutput(@[nodeString("")])
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "assign"), token(TkIdentifier, "foo"), token(TkAssign), token(TkString, "bar")],
        nodeAssign("foo", nodeString("bar"))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "endif")],
        nodeEndIf()
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "endif")],
        nodeEndIf()
      ),
      section(SectionType.Text, @[], nil)
    ],
    output = "!\n\n\n\n    \n\n    \n\n\n\n\n!"
  )

  testCase(
    "don't suppress whitespace only blocks containing output in unreachable blocks",
    "!{% if 1 %}\n\n{% assign bar = 'foo' %}\n{% if true %}\n\n    {% assign foo = 'bar' %}\n\n{% else %}\n    {{ '' }}\n{% endif %}\n\n\n{% endif %}!",
    @[
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "if"), token(TkNumber, "1")],
        nodeIf(nodeNumber(1))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "assign"), token(TkIdentifier, "bar"), token(TkAssign), token(TkString, "foo")],
        nodeAssign("bar", nodeString("foo"))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "if"), token(TkBoolean, "true")],
        nodeIf(nodeBoolean(true))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "assign"), token(TkIdentifier, "foo"), token(TkAssign), token(TkString, "bar")],
        nodeAssign("foo", nodeString("bar"))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "else")],
        nodeElse()
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Output,
        @[token(TkString, "")],
        nodeOutput(@[nodeString("")])
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "endif")],
        nodeEndIf()
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "endif")],
        nodeEndIf()
      ),
      section(SectionType.Text, @[], nil)
    ],
    output = "!\n\n\n\n\n    \n\n\n\n\n!"
  )

  testCase(
    "don't suppress whitespace only case blocks containing output",
    "!{% assign x = 1 %}{% case x %}\n\n  {% when 1 %}\n    {% assign foo = 'bar' %}\n\n  {% when 2 %}\n    {{ '' }}\n\n{% endcase %}!",
    @[
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "assign"), token(TkIdentifier, "x"), token(TkAssign), token(TkNumber, "1")],
        nodeAssign("x", nodeNumber(1))
      ),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "case"), token(TkIdentifier, "x")],
        nodeCase(nodeIdentifier("x"))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "when"), token(TkNumber, "1")],
        nodeWhen(@[nodeNumber(1)])
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "assign"), token(TkIdentifier, "foo"), token(TkAssign), token(TkString, "bar")],
        nodeAssign("foo", nodeString("bar"))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "when"), token(TkNumber, "2")],
        nodeWhen(@[nodeNumber(2)])
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Output,
        @[token(TkString, "")],
        nodeOutput(@[nodeString("")])
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "endcase")],
        nodeEndCase()
      ),
      section(SectionType.Text, @[], nil)
    ],
    output = "!\n    \n\n  !"
  )

  testCase(
    "don't suppress whitespace only unless blocks containing output in nested blocks",
    "!{% unless false %}\n\n{% assign bar = 'foo' %}\n{% unless false %}\n    {{ '' }}\n\n    {% assign foo = 'bar' %}\n\n{% endunless %}\n\n\n{% endunless %}!",
    @[
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "unless"), token(TkBoolean, "false")],
        nodeUnless(nodeBoolean(false))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "assign"), token(TkIdentifier, "bar"), token(TkAssign), token(TkString, "foo")],
        nodeAssign("bar", nodeString("foo"))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "unless"), token(TkBoolean, "false")],
        nodeUnless(nodeBoolean(false))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Output,
        @[token(TkString, "")],
        nodeOutput(@[nodeString("")])
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "assign"), token(TkIdentifier, "foo"), token(TkAssign), token(TkString, "bar")],
        nodeAssign("foo", nodeString("bar"))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "endunless")],
        nodeEndUnless()
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "endunless")],
        nodeEndUnless()
      ),
      section(SectionType.Text, @[], nil)
    ],
    output = "!\n\n\n\n    \n\n    \n\n\n\n\n!"
  )

  testCase(
    "suppress whitespace only case blocks",
    "!{% assign x = 1 %}{% case x %}\n\n  {% when 1 %}\n    {% assign foo = 'bar' %}\n\n\n{% endcase %}!",
    @[
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "assign"), token(TkIdentifier, "x"), token(TkAssign), token(TkNumber, "1")],
        nodeAssign("x", nodeNumber(1))
      ),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "case"), token(TkIdentifier, "x")],
        nodeCase(nodeIdentifier("x"))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "when"), token(TkNumber, "1")],
        nodeWhen(@[nodeNumber(1)])
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "assign"), token(TkIdentifier, "foo"), token(TkAssign), token(TkString, "bar")],
        nodeAssign("foo", nodeString("bar"))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "endcase")],
        nodeEndCase()
      ),
      section(SectionType.Text, @[], nil)
    ],
    output = "!!"
  )

  testCase(
    "suppress whitespace only if blocks",
    "!{% if true %}\n\n{% assign bar = 'foo' %}\n{% if true %}\n\n\n    {% assign foo = 'bar' %}\n\n{% endif %}\n\n\n{% endif %}!",
    @[
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "if"), token(TkBoolean, "true")],
        nodeIf(nodeBoolean(true))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "assign"), token(TkIdentifier, "bar"), token(TkAssign), token(TkString, "foo")],
        nodeAssign("bar", nodeString("foo"))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "if"), token(TkBoolean, "true")],
        nodeIf(nodeBoolean(true))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "assign"), token(TkIdentifier, "foo"), token(TkAssign), token(TkString, "bar")],
        nodeAssign("foo", nodeString("bar"))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "endif")],
        nodeEndIf()
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "endif")],
        nodeEndIf()
      ),
      section(SectionType.Text, @[], nil)
    ],
    output = "!!"
  )

  testCase(
    "suppress whitespace only unless blocks",
    "!{% unless false %}\n\n{% assign bar = 'foo' %}\n{% unless false %}\n\n\n    {% assign foo = 'bar' %}\n\n{% endunless %}\n\n\n{% endunless %}!",
    @[
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "unless"), token(TkBoolean, "false")],
        nodeUnless(nodeBoolean(false))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "assign"), token(TkIdentifier, "bar"), token(TkAssign), token(TkString, "foo")],
        nodeAssign("bar", nodeString("foo"))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "unless"), token(TkBoolean, "false")],
        nodeUnless(nodeBoolean(false))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "assign"), token(TkIdentifier, "foo"), token(TkAssign), token(TkString, "bar")],
        nodeAssign("foo", nodeString("bar"))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "endunless")],
        nodeEndUnless()
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "endunless")],
        nodeEndUnless()
      ),
      section(SectionType.Text, @[], nil)
    ],
    output = "!!"
  )

  testCase(
    "suppress whitespace surrounding a capture block",
    "!{% if true %}\n\n{% capture foo %}\n{{ '' }}\n{% endcapture %}\n\n{% endif %}!",
    @[
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "if"), token(TkBoolean, "true")],
        nodeIf(nodeBoolean(true))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "capture"), token(TkIdentifier, "foo")],
        nodeCapture("foo")
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Output,
        @[token(TkString, "")],
        nodeOutput(@[nodeString("")])
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "endcapture")],
        nodeEndCapture()
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "endif")],
        nodeEndIf()
      ),
      section(SectionType.Text, @[], nil)
    ],
    output = "!!"
  )

  testCase(
    "suppress whitespace surrounding an empty capture block",
    "!{% if true %}\n\n{% capture foo %}{% endcapture %}\n\n{% endif %}!",
    @[
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "if"), token(TkBoolean, "true")],
        nodeIf(nodeBoolean(true))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "capture"), token(TkIdentifier, "foo")],
        nodeCapture("foo")
      ),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "endcapture")],
        nodeEndCapture()
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "endif")],
        nodeEndIf()
      ),
      section(SectionType.Text, @[], nil)
    ],
    output = "!!"
  )

  testCase(
    "white space control with  carriage return, newline and spaces",
    "\r\n{% if customer -%}\r\nWelcome back,  {{ customer.first_name -}} !\r\n {%- endif -%}",
    @[
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "if"), token(TkIdentifier, "customer")],
        nodeIf(nodeIdentifier("customer"))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "customer"),
          token(TkDot),
          token(TkIdentifier, "first_name")
        ],
        nodeOutput(@[nodeDot(nodeIdentifier("customer"), "first_name")])
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "endif")],
        nodeEndIf()
      )
    ],
    context = %*{"customer": {"first_name": "Holly"}},
    output = "\r\nWelcome back,  Holly!"
  )

  testCase(
    "white space control with carriage return and spaces",
    "\r{% if customer -%}\rWelcome back,  {{ customer.first_name -}} !\r {%- endif -%}",
    @[
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "if"), token(TkIdentifier, "customer")],
        nodeIf(nodeIdentifier("customer"))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "customer"),
          token(TkDot),
          token(TkIdentifier, "first_name")
        ],
        nodeOutput(@[nodeDot(nodeIdentifier("customer"), "first_name")])
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "endif")],
        nodeEndIf()
      )
    ],
    context = %*{"customer": {"first_name": "Holly"}},
    output = "\rWelcome back,  Holly!"
  )

  testCase(
    "white space control with newlines and spaces",
    "\n{% if customer -%}\nWelcome back,  {{ customer.first_name -}} !\n {%- endif -%}",
    @[
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "if"), token(TkIdentifier, "customer")],
        nodeIf(nodeIdentifier("customer"))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "customer"),
          token(TkDot),
          token(TkIdentifier, "first_name")
        ],
        nodeOutput(@[nodeDot(nodeIdentifier("customer"), "first_name")])
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "endif")],
        nodeEndIf()
      )
    ],
    context = %*{"customer": {"first_name": "Holly"}},
    output = "\nWelcome back,  Holly!"
  )

  testCase(
    "white space control with newlines, tabs and spaces",
    "\n\t{% if customer -%}\t\nWelcome back,  {{ customer.first_name -}}\t !\r\n {%- endif -%}",
    @[
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "if"), token(TkIdentifier, "customer")],
        nodeIf(nodeIdentifier("customer"))
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "customer"),
          token(TkDot),
          token(TkIdentifier, "first_name")
        ],
        nodeOutput(@[nodeDot(nodeIdentifier("customer"), "first_name")])
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "endif")],
        nodeEndIf()
      )
    ],
    context = %*{"customer": {"first_name": "Holly"}},
    output = "\n\tWelcome back,  Holly!"
  )

  testCase(
    "white space control with raw tags",
    "! {% raw %}{{ hello }}{% endraw %} !\n! {%- raw -%}{{ hello }}{%- endraw -%} !",
    @[
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "raw")],
        nodeRaw("{{ hello }}")
      ),
      section(SectionType.Text, @[], nil),
      section(
        SectionType.Tag,
        @[token(TkIdentifier, "raw")],
        nodeRaw("{{ hello }}")
      )
    ],
    output = "! {{ hello }} !\n!{{ hello }}!"
  )