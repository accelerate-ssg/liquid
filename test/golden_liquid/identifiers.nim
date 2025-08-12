

suite "identifiers":
  testCase(
    "ascii lowercase",
    "{% assign foo = 'hello' %}{{ foo }} {{ bar }}",
    context = %*{"bar": "goodbye"},
    output = "hello goodbye",
    strict = true
  )

  testCase(
    "ascii uppercase",
    "{% assign FOO = 'hello' %}{{ FOO }} {{ BAR }}",
    context = %*{"BAR": "goodbye"},
    output = "hello goodbye",
    strict = true
  )

  testCase(
    "at sign",
    "{{ @foo }}",
    context = %*{"@foo": "hello"},
    error = true,
    strict = true
  )

  testCase(
    "capture ascii lowercase",
    "{% capture foo %}hello{% endcapture %}{{ foo }}",
    output = "hello",
    strict = true
  )

  testCase(
    "capture ascii uppercase",
    "{% capture FOO %}hello{% endcapture %}{{ FOO }}",
    output = "hello",
    strict = true
  )

  testCase(
    "capture digits",
    "{% capture foo1 %}hello{% endcapture %}{{ foo1 }}",
    output = "hello",
    strict = true
  )

  testCase(
    "capture hyphens",
    "{% capture foo-a %}hello {{ bar-b }}{% endcapture %}{{ foo-a }}",
    context = %*{"bar-b": "goodbye"},
    output = "hello goodbye",
    strict = true
  )

  testCase(
    "capture leading hyphen",
    "{% capture -foo %}hello {{ -bar }}{% endcapture %}{{ -foo }}",
    context = %*{"-bar": "goodbye"},
    error = true,
    strict = true
  )

  testCase(
    "capture leading underscore",
    "{% capture _foo %}hello {{ _bar }}{% endcapture %}{{ _foo }}",
    context = %*{"_bar": "goodbye"},
    output = "hello goodbye",
    strict = true
  )

  testCase(
    "capture only digits",
    "{% capture 123 %}hello{% endcapture %}{{ 123 }}",
    output = "123",
    strict = true
  )

  testCase(
    "capture only underscore",
    "{% capture _ %}hello {{ __ }}{% endcapture %}{{ _ }}",
    context = %*{"__": "goodbye"},
    output = "hello goodbye",
    strict = true
  )

  testCase(
    "capture underscore",
    "{% capture foo_a %}hello {{ bar_b }}{% endcapture %}{{ foo_a }}",
    context = %*{"bar_b": "goodbye"},
    output = "hello goodbye",
    strict = true
  )

  testCase(
    "decrement with a hyphen",
    "{% decrement f-oo %}{% decrement f-oo %}",
    output = "-1-2",
    strict = true
  )

  testCase(
    "digits",
    "{% assign foo1 = 'hello' %}{{ foo1 }} {{ bar2 }}",
    context = %*{"bar2": "goodbye"},
    output = "hello goodbye",
    strict = true
  )

  testCase(
    "hyphen in for loop target",
    "{% for x in f-oo %}{{ x }}{% endfor %}",
    context = %*{"f-oo": [1, 2, 3]},
    output = "123",
    strict = true
  )

  testCase(
    "hyphen in for loop variable",
    "{% for x-y in foo %}{{ x-y }}{% endfor %}",
    context = %*{"foo": [1, 2, 3]},
    output = "123",
    strict = true
  )

  testCase(
    "hyphens",
    "{% assign foo-a = 'hello' %}{{ foo-a }} {{ bar-b }}",
    context = %*{"bar-b": "goodbye"},
    output = "hello goodbye",
    strict = true
  )

  testCase(
    "increment with a hyphen",
    "{% increment f-oo %}{% increment f-oo %}",
    output = "01",
    strict = true
  )

  testCase(
    "leading hyphen",
    "{% assign -foo = 'hello' %}{{ -foo }} {{ -bar }}",
    context = %*{"-bar": "goodbye"},
    error = true,
    strict = true
  )

  testCase(
    "leading hyphen in for loop target",
    "{% for x in -foo %}{{ x }}{% endfor %}",
    context = %*{"-foo": [1, 2, 3]},
    error = true,
    strict = true
  )

  testCase(
    "leading underscore",
    "{% assign _foo = 'hello' %}{{ _foo }} {{ _bar }}",
    context = %*{"_bar": "goodbye"},
    output = "hello goodbye",
    strict = true
  )

  testCase(
    "only digits",
    "{% assign 123 = 'hello' %}{{ 123 }} {{ 456 }}",
    context = %*{"456": "goodbye"},
    output = "123 456",
    strict = true
  )

  testCase(
    "only underscore",
    "{% assign _ = 'hello' %}{{ _ }} {{ __ }}",
    context = %*{"__": "goodbye"},
    output = "hello goodbye",
    strict = true
  )

  testCase(
    "trailing question mark assign",
    "{% assign foo? = 'hello' %}{{ foo? }}",
    error = true,
    strict = true
  )

  testCase(
    "trailing question mark in for loop target",
    "{% for x in foo? %}{{ x }}{% endfor %}",
    context = %*{"foo?": [1, 2, 3]},
    output = "123",
    strict = true
  )

  testCase(
    "trailing question mark in for loop variable",
    "{% for x? in foo %}{{ x? }}{% endfor %}",
    context = %*{"foo": [1, 2, 3]},
    output = "123"
  )

  testCase(
    "trailing question mark output",
    "{{ bar? }}",
    context = %*{"bar?": "goodbye"},
    output = "goodbye",
    strict = true
  )

  testCase(
    "underscore",
    "{% assign foo_a = 'hello' %}{{ foo_a }} {{ bar_b }}",
    context = %*{"bar_b": "goodbye"},
    output = "hello goodbye",
    strict = true
  )
