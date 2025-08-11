suite "case/when":
  testCase(
    "'when' expression using an identifier",
    "{% case title %}{% when other %}foo{% when 'goodbye' %}bar{% endcase %}",
    context = %*{"title": "Hello", "other": "Hello"},
    output = "foo"
  )

  testCase(
    "'when' expression using an out of scope identifier",
    "{% case title %}{% when nosuchthing %}foo{% when 'Hello' %}bar{% endcase %}",
    context = %*{"title": "Hello"},
    output = "bar"
  )

  testCase(
    "comma separated when expression",
    "{% case title %}{% when 'foo' %}foo{% when 'bar', 'Hello' %}bar{% endcase %}",
    context = %*{"title": "Hello"},
    output = "bar"
  )

  testCase(
    "'or' separated when expression",
    "{% case title %}{% when 'foo' %}foo{% when 'bar' or 'Hello' %}bar{% endcase %}",
    context = %*{"title": "Hello"},
    output = "bar"
  )

  testCase(
    "comma string literal",
    "{% case foo %}{% when 'foo' %}bar{% when ',' %}comma{% endcase %}",
    context = %*{"foo": ","},
    output = "comma"
  )

  testCase(
    "empty when tag",
    "{% case foo %}{% when %}bar{% endcase %}",
    context = %*{"foo": "bar"},
    error = true
  )

  testCase(
    "with default",
    "{% case title %}{% when 'foo' %}foo{% else %}bar{% endcase %}",
    context = %*{"title": "Hello"},
    output = "bar"
  )
