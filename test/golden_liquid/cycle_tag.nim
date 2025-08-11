

suite "cycle tag":
  testCase(
    "changing variable name",
    "{% cycle a: 1, 2, 3 %}{% assign a = 'bar' %}{% cycle a: 1, 2, 3 %}{% cycle a: 1, 2, 3 %}",
    context = %*{"a": "foo"},
    output = "112"
  )

  testCase(
    "different items",
    "{% cycle '1', '2', '3' %}{% cycle '1', '2' %}{% cycle '1', '2', '3' %}",
    output = "112"
  )

  testCase(
    "integers",
    "{% cycle 1, 2, 3 %}{% cycle 1, 2, 3 %}{% cycle 1, 2, 3 %}",
    output = "123"
  )

  testCase(
    "multiple undefined variable names",
    "{% cycle a: 1, 2, 3 %}{% cycle b: 1, 2, 3 %}{% cycle a: 1, 2, 3 %}",
    output = "123"
  )

  testCase(
    "named with different items",
    "{% cycle 'a': 1, 2, 3 %}{% cycle 'a': 7, 8, 9 %}{% cycle 'a': 1, 2, 3 %}",
    output = "183"
  )

  testCase(
    "named with different number of arguments",
    "{% cycle a: '1', '2' %}{% cycle a: '1', '2', '3' %}{% cycle a: '1' %}",
    output = "12"
  )

  testCase(
    "named with growing number of arguments",
    "{% cycle a: '1' %}{% cycle a: '1', '2' %}{% cycle a: '1', '2', '3' %}",
    output = "112"
  )

  testCase(
    "named with shrinking number of arguments",
    "{% cycle a: '1', '2', '3' %}{% cycle a: '1', '2' %}{% cycle a: '1' %}",
    output = "121"
  )

  testCase(
    "no identifier",
    "{% cycle 'some', 'other' %}{% cycle 'some', 'other' %}{% cycle 'some', 'other' %}",
    output = "someothersome"
  )

  testCase(
    "undefined variable names mixed with no name",
    "{% cycle a: 1, 2, 3 %}{% cycle b: 1, 2, 3 %}{% cycle 1, 2, 3 %}",
    output = "121"
  )

  testCase(
    "variable name",
    "{% cycle a: 1, 2, 3 %}{% cycle a: 1, 2, 3 %}{% cycle a: 1, 2, 3 %}",
    context = %*{"a": "foo"},
    output = "123"
  )

  testCase(
    "with identifier",
    "{% cycle 'foo': 'some', 'other' %}{% cycle 'some', 'other' %}{% cycle 'foo': 'some', 'other' %}",
    output = "someothersome"
  )
