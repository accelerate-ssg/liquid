[
  {
    "name": "continue after raw",
    "template": "{% raw %} {% some raw content %} {% endraw %}a literal",
    "want": " {% some raw content %} a literal",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "literal",
    "template": "{% raw %}foo{% endraw %}",
    "want": "foo",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "partial tag",
    "template": "{% raw %} %} {% }} {{ {% endraw %}",
    "want": " %} {% }} {{ ",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "statement",
    "template": "{% raw %}{{ foo }}{% endraw %}",
    "want": "{{ foo }}",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "tag",
    "template": "{% raw %}{% assign x = 1 %}{% endraw %}",
    "want": "{% assign x = 1 %}",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]