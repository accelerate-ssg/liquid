

suite "increment and decrement":
  testCase(
    "increment and decrement named counter",
    "{% decrement foo %} {% decrement foo %} {% increment foo %}",
    output = "-1 -2 -2"
  )

  testCase(
    "named counter",
    "{% decrement foo %}{{ foo }} {% decrement foo %}{{ foo }}",
    output = "-1-1 -2-2"
  )
