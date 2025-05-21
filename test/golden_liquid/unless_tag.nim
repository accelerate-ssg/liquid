[
  {
    "name": "alternative block",
    "template": "{% unless true %}foo{% else %}bar{% endunless %}",
    "want": "bar",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "array is equal to array",
    "template": "{% assign x = 'a,b,c' | split: ',' %}{% assign y = 'a,b,c' | split: ',' %}{% unless x == y %}true{% else %}false{% endunless %}",
    "want": "false",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "array is equal to array from context",
    "template": "{% assign y = 'a,b,c' | split: ',' %}{% unless x == y %}true{% else %}false{% endunless %}",
    "want": "false",
    "context": {
      "x": [
        "a",
        "b",
        "c"
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "blocks that contain only whitespace are not rendered",
    "template": "{% unless false %}  {% endunless %}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "conditional alternative block",
    "template": "{% unless true %}foo{% elsif true %}bar{% endunless %}",
    "want": "bar",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "conditional alternative block with default",
    "template": "{% unless true %}foo{% elsif false %}bar{% else %}hello{% endunless %}",
    "want": "hello",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "else tag expressions are ignored",
    "template": "{% unless true %}1{% else nonsense %}2{% endunless %}",
    "want": "2",
    "context": {},
    "partials": {},
    "error": false,
    "strict": true
  },
  {
    "name": "extra else blocks are ignored",
    "template": "{% unless true %}1{% else %}2{% else %}3{% endunless %}",
    "want": "2",
    "context": {},
    "partials": {},
    "error": false,
    "strict": true
  },
  {
    "name": "extra elsif blocks are ignored",
    "template": "{% unless true %}1{% else %}2{% elsif true %}3{% endunless %}",
    "want": "2",
    "context": {},
    "partials": {},
    "error": false,
    "strict": true
  },
  {
    "name": "literal false condition",
    "template": "{% unless false %}foo{% endunless %}",
    "want": "foo",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "literal true condition",
    "template": "{% unless true %}foo{% endunless %}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "one is not equal to true",
    "template": "{% unless 1 == true %}Hello{% else %}Goodbye{% endunless %}",
    "want": "Hello",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "zero is not equal to false",
    "template": "{% unless 0 == false %}Hello{% else %}Goodbye{% endunless %}",
    "want": "Hello",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "zero is truthy",
    "template": "{% unless 0 %}Hello{% else %}Goodbye{% endunless %}",
    "want": "Goodbye",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]