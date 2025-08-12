

suite "if statement":
  testCase(
    "0.0 is truthy",
    "{% if 0.0 %}Hello{% else %}Goodbye{% endif %}",
    output = "Hello"
  )

  testCase(
    "alternate not equal condition",
    "{% if product.title <> 'foo' %}baz{% endif %}",
    context = %*{"product": {"title": "foo"}}
  )

  testCase(
    "array is equal to array",
    "{% assign x = 'a,b,c' | split: ',' %}{% assign y = 'a,b,c' | split: ',' %}{% if x == y %}true{% else %}false{% endif %}",
    output = "true"
  )

  testCase(
    "array is equal to array from context",
    "{% assign y = 'a,b,c' | split: ',' %}{% if x == y %}true{% else %}false{% endif %}",
    context = %*{"x": ["a", "b", "c"]},
    output = "true"
  )

  testCase(
    "blocks that contain only whitespace and comments are not rendered",
    "{% if true %} {% comment %} this is blank {% endcomment %} {% endif %}"
  )

  testCase(
    "blocks that contain only whitespace are not rendered",
    "{% if true %}  {% elsif false %} {% else %} {% endif %}"
  )

  testCase(
    "condition with conditional alternative",
    "{% if product.title == 'hello' %}foo{% elsif product.title == 'foo' %}bar{% endif %}",
    context = %*{"product": {"title": "foo"}},
    output = "bar"
  )

  testCase(
    "condition with conditional alternative and final alternative",
    "{% if product.title == 'hello' %}foo{% elsif product.title == 'goodbye' %}bar{% else %}baz{% endif %}",
    context = %*{"product": {"title": "foo"}},
    output = "baz"
  )

  testCase(
    "condition with literal consequence",
    "{% if product.title == 'foo' %}bar{% endif %}",
    context = %*{"product": {"title": "foo"}},
    output = "bar"
  )

  testCase(
    "condition with literal consequence and literal alternative",
    "{% if product.title == 'hello' %}bar{% else %}baz{% endif %}",
    context = %*{"product": {"title": "foo"}}
  )

  testCase(
    "conditional alternative with default",
    "{% if false %}foo{% elsif false %}bar{% else %}hello{% endif %}"
  )

  testCase(
    "contains condition",
    "{% if product.tags contains 'garden' %}baz{% endif %}",
    context = %*{"product": {"tags": ["sports", "garden"]}}
  )

  testCase(
    "else tag expressions are ignored",
    "{% if false %}1{% else nonsense %}2{% endif %}",
    strict = true
  )

  testCase(
    "empty array equals special empty",
    "{% if x == empty %}TRUE{% else %}FALSE{% endif %}",
    context = %*{"x": []}
  )

  testCase(
    "empty array is truthy",
    "{% if x %}TRUE{% else %}FALSE{% endif %}",
    context = %*{"x": []}
  )

  testCase(
    "empty object equals special empty",
    "{% if x == empty %}TRUE{% else %}FALSE{% endif %}",
    context = %*{"x": {}}
  )

  testCase(
    "empty object is truthy",
    "{% if x %}TRUE{% else %}FALSE{% endif %}",
    context = %*{"x": {}}
  )

  testCase(
    "empty string is truthy",
    "{% if '' %}TRUE{% else %}FALSE{% endif %}"
  )

  testCase(
    "extra else blocks are ignored",
    "{% if false %}1{% else %}2{% else %}3{% endif %}",
    strict = true
  )

  testCase(
    "extra elsif blocks are ignored",
    "{% if false %}1{% else %}2{% elsif true %}3{% endif %}",
    strict = true
  )

  testCase(
    "int does not equal string",
    "{% if 1 == '1' %}true{% else %}false{% endif %}"
  )

  testCase(
    "int equals float",
    "{% if 1 == 1.0 %}true{% else %}false{% endif %}"
  )

  testCase(
    "literal false condition",
    "{% if false %}{% endif %}"
  )

  testCase(
    "literal nil is falsy",
    "{% if nil %}bar{% else %}foo{% endif %}"
  )

  testCase(
    "logical operators are right associative",
    "{% if true and false and false or true %}hello{% endif %}"
  )

  testCase(
    "nested condition in the consequence block",
    "{% if product %}{% if title == 'Hello' %}baz{% endif %}{% endif %}",
    context = %*{"product": {"title": "foo"}, "title": "Hello"}
  )

  testCase(
    "nested condition, alternative in the consequence block",
    "{% if product %}{% if title == 'goodbye' %}baz{% else %}hello{% endif %}{% endif %}",
    context = %*{"product": {"title": "foo"}, "title": "Hello"}
  )

  testCase(
    "non-empty hash is truthy",
    "{% if product %}bar{% else %}foo{% endif %}",
    context = %*{"product": {"title": "foo"}}
  )

  testCase(
    "not equal condition",
    "{% if product.title != 'foo' %}baz{% endif %}",
    context = %*{"product": {"title": "foo"}}
  )

  testCase(
    "one is not equal to true",
    "{% if 1 == true %}Hello{% else %}Goodbye{% endif %}"
  )

  testCase(
    "range equals range",
    "{% assign foo = (1..3) %}{% if foo == (1..3) %}true{% else %}false{% endif %}"
  )

  testCase(
    "string contains int",
    "{% if 'hel9lo' contains 9 %}TRUE{% else %}FALSE{% endif %}",
    context = %*{"x": {}}
  )

  testCase(
    "string does not equal int",
    "{% if '1' == 1 %}true{% else %}false{% endif %}"
  )

  testCase(
    "string greater than int",
    "{% if '2' > 1 %}true{% else %}false{% endif %}",
    # The original Golden Liquid tests claim this is an error, but testing it in Ruby shows that it is not.
    # error = true
    output = "true"
  )

  testCase(
    "string is greater than or equal to string",
    "{% if 'abc' >= 'acb' %}true{% else %}false{% endif %}"
  )

  testCase(
    "string is greater than string",
    "{% if 'abc' > 'acb' %}true{% else %}false{% endif %}"
  )

  testCase(
    "string is less than or equal to string",
    "{% if 'abc' <= 'acb' %}true{% else %}false{% endif %}"
  )

  testCase(
    "string is less than string",
    "{% if 'abc' < 'acb' %}true{% else %}false{% endif %}"
  )

  testCase(
    "string is not greater than or equal to string",
    "{% if 'bbb' >= 'aaa' %}true{% else %}false{% endif %}"
  )

  testCase(
    "string is not greater than string",
    "{% if 'bbb' > 'aaa' %}true{% else %}false{% endif %}"
  )

  testCase(
    "string is not less than or equal to string",
    "{% if 'bbb' <= 'aaa' %}true{% else %}false{% endif %}"
  )

  testCase(
    "string is not less than string",
    "{% if 'bbb' < 'aaa' %}true{% else %}false{% endif %}"
  )

  testCase(
    "undefined is equal to nil",
    "{% if nosuchthing == nil %}TRUE{% else %}FALSE{% endif %}"
  )

  testCase(
    "undefined is equal to null",
    "{% if nosuchthing == null %}TRUE{% else %}FALSE{% endif %}"
  )

  testCase(
    "undefined variables are falsy",
    "{% if nosuchthing %}bar{% else %}foo{% endif %}"
  )

  testCase(
    "zero is not equal to false",
    "{% if 0 == false %}Hello{% else %}Goodbye{% endif %}"
  )

  testCase(
    "zero is truthy",
    "{% if 0 %}Hello{% else %}Goodbye{% endif %}"
  )

