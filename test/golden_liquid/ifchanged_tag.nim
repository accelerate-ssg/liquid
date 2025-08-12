

suite "ifchanged tag":
  testCase(
    "basic ifchanged",
    "{% ifchanged %}hello{% endifchanged %}",
    output = "hello"
  )

  testCase(
    "ifchanged with expression",
    "{% ifchanged foo %}{{ foo }}{% endifchanged %}",
    context = %*{"foo": "bar"},
    output = "bar"
  )

  testCase(
    "ifchanged with else",
    "{% ifchanged %}hello{% else %}world{% endifchanged %}",
    output = "hello"
  )
