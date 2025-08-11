

suite "echo tag":
  testCase(
    "access an array item by index",
    "{% echo product.tags[1] %}",
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "garden"
  )

  testCase(
    "access an array item by negative index",
    "{% echo product.tags[-2] %}",
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "sports"
  )

  testCase(
    "access an undefined variable by index",
    "{% echo nosuchthing[0] %}",
    output = ""
  )

  testCase(
    "access array item by index stored in a local variable",
    "{% assign i = 1 %}{% echo product.tags[i] %}",
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "garden"
  )

  testCase(
    "assign a variable the value of an existing variable",
    "{% capture some %}hello{% endcapture %}{% assign other = some %}{% assign some = 'foo' %}{% echo some %}-{% echo other %}",
    output = "foo-hello"
  )

  testCase(
    "dump an array from the global context",
    "{% echo product.tags %}",
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "sportsgarden"
  )

  testCase(
    "nothing to echo",
    "{% echo %}",
    output = ""
  )

  testCase(
    "render a float literal",
    "{% echo 1.23 %}",
    output = "1.23"
  )

  testCase(
    "render a global identifier with a filter",
    "{% echo product.title | upcase %}",
    context = %*{"product": {"title": "foo"}},
    output = "FOO"
  )

  testCase(
    "render a string literal",
    "{% echo 'hello' %}",
    output = "hello"
  )

  testCase(
    "render a variable from the global namespace",
    "{% echo product.title %}",
    context = %*{"product": {"title": "foo"}},
    output = "foo"
  )

  testCase(
    "render a variable from the local namespace",
    "{% assign name = 'Brian' %}{% echo name %}",
    output = "Brian"
  )

  testCase(
    "render an integer literal",
    "{% echo 123 %}",
    output = "123"
  )

  testCase(
    "render an undefined property",
    "{% echo product.age %}",
    context = %*{"product": {"title": "foo"}},
    output = ""
  )

  testCase(
    "render an undefined variable",
    "{% echo age %}",
    output = ""
  )

  testCase(
    "traverse variables with bracketed identifiers",
    "{% echo site.data.menu[include.menu][include.locale] %}",
    context = %*{
      "site": {
        "data": {
          "menu": {
            "foo": {
              "bar": "it works!"
            }
          }
        }
      },
      "include": {
        "menu": "foo",
        "locale": "bar"
      }
    },
    output = "it works!"
  )
