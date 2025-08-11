suite "assign tag":
  testCase(
    "assign a filtered literal",
    "{% assign foo = 'foo' | upcase %}{{ foo }}",
    output = "FOO"
  )

  testCase(
    "assign a range literal",
    "{% assign foo = (1..3) %}{{ foo | join: '#' }}",
    output = "1#2#3"
  )

  testCase(
    "assign an existing array",
    "{% assign foo = bar %}{{ foo[0] }}/{{ foo[1] }}",
    context = %*{"bar": ["a", "b", "c"]},
    output = "a/b"
  )

  testCase(
    "assign an item from an existing object with quoted notation",
    "{% assign foo = bar['baz'] %}{{ foo }}",
    context = %*{"bar": {"baz": "hello"}},
    output = "hello"
  )

  testCase(
    "assign to variable with a hyphen",
    "{% assign some-thing = 'foo' %}{{ some-thing }}",
    output = "foo"
  )

  testCase(
    "assign with quoted notation and extra whitespace",
    "{% assign foo = bar[ 'baz'  ] %}{{ foo }}",
    context = %*{"bar": {"baz": "hello"}},
    output = "hello"
  )

  testCase(
    "local variables shadow global variables",
    "{{ foo }}{% assign foo = 'foo' | upcase %}{{ foo }}",
    context = %*{"foo": "bar"},
    output = "barFOO"
  )
