import helpers

suite "concat filter":
  testCase(
    "left value contains non string",
    "{{ a | concat: b | join: '#' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "a"),
          token(TkPipe),
          token(TkIdentifier, "concat"),
          token(TkColon),
          token(TkIdentifier, "b"),
          token(TkPipe),
          token(TkIdentifier, "join"),
          token(TkColon),
          token(TkString, "#")
        ],
        nodeOutput(@[
          nodeFilter(
            "join",
            @[
              nodeFilter(
                "concat",
                @[  
                  nodeVariable("a"),
                  nodeArgument("", nodeVariable("b")),
                ]
              ),
              nodeArgument("", nodeString("#")),
            ]
          )
        ])
      )
    ],
    context = %*{"a": ["a", "b", 5], "b": ["c", "d"]},
    output = "a#b#5#c#d"
  )

  testCase(
    "left value is not array-like",
    "{{ a | concat: b | join: '#' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "a"),
          token(TkPipe),
          token(TkIdentifier, "concat"),
          token(TkColon),
          token(TkIdentifier, "b"),
          token(TkPipe),
          token(TkIdentifier, "join"),
          token(TkColon),
          token(TkString, "#")
        ],
        nodeOutput(@[
          nodeFilter(
            "join",
            @[
              nodeFilter(
                "concat",
                @[  
                  nodeVariable("a"),
                  nodeArgument("", nodeVariable("b")),
                ]
              ),
              nodeArgument("", nodeString("#")),
            ]
          )
        ])
      )
    ],
    context = %*{"a": "ab", "b": ["c", "d"]},
    output = "ab#c#d"
  )

  testCase(
    "missing argument is an error",
    "{{ a | concat | join: '#' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "a"),
          token(TkPipe),
          token(TkIdentifier, "concat"),
          token(TkPipe),
          token(TkIdentifier, "join"),
          token(TkColon),
          token(TkString, "#")
        ],
        nodeOutput(@[
          nodeFilter(
            "join",
            @[
              nodeFilter(
                "concat",
                @[  
                  nodeVariable("a")
                ]
              ),
              nodeArgument("", nodeString("#")),
            ]
          )
        ])
      )
    ],
    context = %*{"a": ["a", "b"]},
    error = true
  )

  testCase(
    "nested left value gets flattened",
    "{{ a | concat: b | join: '#' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "a"),
          token(TkPipe),
          token(TkIdentifier, "concat"),
          token(TkColon),
          token(TkIdentifier, "b"),
          token(TkPipe),
          token(TkIdentifier, "join"),
          token(TkColon),
          token(TkString, "#")
        ],
        nodeOutput(@[
          nodeFilter(
            "join",
            @[
              nodeFilter(
                "concat",
                @[  
                  nodeVariable("a"),
                  nodeArgument("", nodeVariable("b")),
                ]
              ),
              nodeArgument("", nodeString("#")),
            ]
          )
        ])
      )
    ],
    context = %*{"a": [["a", "x"], ["b", ["y", ["z"]]]], "b": ["c", "d"]},
    output = "a#x#b#y#z#c#d"
  )

  testCase(
    "non array-like argument is an error",
    "{{ a | concat: b | join: '#' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "a"),
          token(TkPipe),
          token(TkIdentifier, "concat"),
          token(TkColon),
          token(TkIdentifier, "b"),
          token(TkPipe),
          token(TkIdentifier, "join"),
          token(TkColon),
          token(TkString, "#")
        ],
        nodeOutput(@[
          nodeFilter(
            "join",
            @[
              nodeFilter(
                "concat",
                @[  
                  nodeVariable("a"),
                  nodeArgument("", nodeVariable("b")),
                ]
              ),
              nodeArgument("", nodeString("#")),
            ]
          )
        ])
      )
    ],
    context = %*{"a": ["a", "b"], "b": 5},
    error = true
  )

  testCase(
    "range literal concat filter left value",
    "{{ (1..3) | concat: foo | join: '#' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkLeftParen),
          token(TkNumber, "1"),
          token(TkRange),
          token(TkNumber, "3"),
          token(TkRightParen),
          token(TkPipe),
          token(TkIdentifier, "concat"),
          token(TkColon),
          token(TkIdentifier, "foo"),
          token(TkPipe),
          token(TkIdentifier, "join"),
          token(TkColon),
          token(TkString, "#")
        ],
        nodeOutput(@[
          nodeFilter(
            "join",
            @[
              nodeFilter(
                "concat",
                @[  
                  nodeRange(
                    nodeNumber(1),
                    nodeNumber(3)
                  ),
                  nodeArgument("", nodeVariable("foo")),
                ]
              ),
              nodeArgument("", nodeString("#")),
            ]
          )
        ])
      )
    ],
    context = %*{"foo": [5, 6, 7]},
    output = "1#2#3#5#6#7"
  )

  testCase(
    "two arrays of strings",
    "{{ a | concat: b | join: '#' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "a"),
          token(TkPipe),
          token(TkIdentifier, "concat"),
          token(TkColon),
          token(TkIdentifier, "b"),
          token(TkPipe),
          token(TkIdentifier, "join"),
          token(TkColon),
          token(TkString, "#")
        ],
        nodeOutput(@[
          nodeFilter(
            "join",
            @[
              nodeFilter(
                "concat",
                @[  
                  nodeVariable("a"),
                  nodeArgument("", nodeVariable("b")),
                ]
              ),
              nodeArgument("", nodeString("#")),
            ]
          )
        ])
      )
    ],
    context = %*{"a": ["a", "b"], "b": ["c", "d"]},
    output = "a#b#c#d"
  )

  testCase(
    "undefined argument is an error",
    "{{ a | concat: nosuchthing | join: '#' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "a"),
          token(TkPipe),
          token(TkIdentifier, "concat"),
          token(TkColon),
          token(TkIdentifier, "nosuchthing"),
          token(TkPipe),
          token(TkIdentifier, "join"),
          token(TkColon),
          token(TkString, "#")
        ],
        nodeOutput(@[
          nodeFilter(
            "join",
            @[
              nodeFilter(
                "concat",
                @[  
                  nodeVariable("a"),
                  nodeArgument("", nodeVariable("nosuchthing")),
                ]
              ),
              nodeArgument("", nodeString("#")),
            ]
          )
        ])
      )
    ],
    context = %*{"a": ["a", "b"]},
    error = true
  )

  testCase(
    "undefined left value",
    "{{ nosuchthing | concat: b | join: '#' }}",
    @[
      section(
        SectionType.Output,
        @[
          token(TkIdentifier, "nosuchthing"),
          token(TkPipe),
          token(TkIdentifier, "concat"),
          token(TkColon),
          token(TkIdentifier, "b"),
          token(TkPipe),
          token(TkIdentifier, "join"),
          token(TkColon),
          token(TkString, "#")
        ],
        nodeOutput(@[
          nodeFilter(
            "join",
            @[
              nodeFilter(
                "concat",
                @[  
                  nodeVariable("nosuchthing"),
                  nodeArgument("", nodeVariable("b")),
                ]
              ),
              nodeArgument("", nodeString("#")),
            ]
          )
        ])
      )
    ],
    context = %*{"b": ["c", "d"]},
    output = "c#d"
  )
