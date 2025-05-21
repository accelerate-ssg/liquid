import helpers

suite "capture tag":
  testCase(
    "assign to a variable from a captured variable",
    """{% capture some %}hello{% endcapture %}{% assign other = some %}{{ some }}-{{ other }}""",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "capture"),
          token(TkIdentifier, "some"),
        ],
        nodeCapture("some")
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "endcapture")
        ],
        nodeEndCapture()
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "assign"),
          token(TkIdentifier, "other"),
          token(TkAssign),
          token(TkIdentifier, "some")
        ],
        nodeAssign("other", nodeVariable("some"))
      ),
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "some")
        ],
        nodeOutput(@[nodeVariable("some")])
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "other")
        ],
        nodeOutput(@[nodeVariable("other")])
      )
    ],
    output = "hello-hello"
  )

  testCase(
    "capture into a variable with a hyphen",
    """{% capture this-thing %}Hello, {{ customer.first_name }}.{% endcapture %}{{ this-thing }}""",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "capture"),
          token(TkIdentifier, "this-thing")
        ],
        nodeCapture("this-thing")
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "customer"),
          token(TkDot),
          token(TkIdentifier, "first_name")
        ],
        nodeOutput(@[nodeVariable("customer.first_name")])
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "endcapture")
        ],
        nodeEndCapture()
      ),
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "this-thing")
        ],
        nodeOutput(@[nodeVariable("this-thing")])
      )
    ],
    context = %*{"customer": {"first_name": "Holly"}},
    output = "Hello, Holly."
  )

  testCase(
    "capture template literal and global variable",
    """{% capture greeting %}Hello, {{ customer.first_name }}.{% endcapture %}{{ greeting }}""",
    @[
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "capture"),
          token(TkIdentifier, "greeting")
        ],
        nodeCapture("greeting")
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "customer"),
          token(TkDot),
          token(TkIdentifier, "first_name")
        ],
        nodeOutput(@[nodeVariable("customer.first_name")])
      ),
      section(
        SectionType.Text,
        @[],
        nil
      ),
      section(
        SectionType.Tag,
        @[
          token(TkKeyword, "endcapture")
        ],
        nodeEndCapture()
      ),
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "greeting")
        ],
        nodeOutput(@[nodeVariable("greeting")])
      )
    ],
    context = %*{"customer": {"first_name": "Holly"}},
    output = "Hello, Holly."
  )
