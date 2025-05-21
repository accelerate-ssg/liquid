[
  {
    "name": "assign and increment",
    "template": "{% assign foo = 5 %}{{ foo }} {% increment foo %} {% increment foo %} {{ foo }}",
    "want": "5 0 1 5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "incrementing counter renders before incrementing",
    "template": "{% increment foo %} {{ foo }}",
    "want": "0 1",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "multiple named counters",
    "template": "{% increment foo %} {% increment bar %} {% increment foo %} {% increment bar %}",
    "want": "0 0 1 1",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "named counter",
    "template": "{% increment foo %} {% increment foo %} {% increment foo %}",
    "want": "0 1 2",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "named counters are in scope for subsequent expressions",
    "template": "{% increment foo %} {% increment foo %} {% if foo > 0 %}{{ foo }}{% endif %}",
    "want": "0 1 2",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]