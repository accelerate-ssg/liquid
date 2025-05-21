[
  {
    "name": "can't comment tags",
    "template": "{%- # {% echo 'hello world' %} -%}",
    "want": " -%}",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "comment with double quote",
    "template": "{%# some \"comment %}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "comment with double quoted string",
    "template": "{%# some \"comment\" %}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "comment with single quote",
    "template": "{%# some 'comment %}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "comment with single quoted string",
    "template": "{%# some 'comment' %}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "comment with u2018",
    "template": "{%# some ‘comment %}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "comment with u201C",
    "template": "{%# some “comment %}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "empty",
    "template": "{%#%}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "enforce leading hash",
    "template": "{%-\n  # spread inline comments\n  over multiple lines\n-%}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "liquid tag",
    "template": "{% liquid \n  # first comment line\n  # second comment line\n\n  # another comment line\n  echo 'Hello '\n\n  # more comments\n  echo 'goodbye'\n-%}",
    "want": "Hello goodbye",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "lots of hashes in a liquid tag",
    "template": "{% liquid\n  ##########################\n  # spread inline comments #\n  ##########################\n-%}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "multiple lines",
    "template": "{%-\n  # spread inline comments\n  # over multiple lines\n-%}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "no padding after the hash",
    "template": "{%#some comment %}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "no whitespace control no padding",
    "template": "{%# some comment %}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "no whitespace control with padding",
    "template": "{% # some comment %}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "with whitespace control and padding",
    "template": "{%- # some comment -%}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "with whitespace control no padding",
    "template": "{%-# some comment -%}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]