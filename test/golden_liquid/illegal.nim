[
  {
    "name": "no addition operator",
    "template": "{% assign x = 1 + 2 %}{{ x }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": true
  },
  {
    "name": "no multiplication operator",
    "template": "{% assign x = 2 %}{{ x * 3 }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": true
  },
  {
    "name": "no subtraction operator",
    "template": "{% assign x = 1 - 2 %}{{ x }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": true
  },
  {
    "name": "unknown tag",
    "template": "{% nosuchthing %}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": true
  }
]