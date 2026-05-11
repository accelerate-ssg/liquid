[
  {
    "name": "arg string not a number",
    "template": "{{ \"10\" | plus: \"foo\" }}",
    "want": "10",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "float value and float arg",
    "template": "{{ 10.1 | plus: 2.2 }}",
    "want": "12.3",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "integer value and float arg",
    "template": "{{ 10 | plus: 2.0 }}",
    "want": "12.0",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "integer value and integer arg",
    "template": "{{ 10 | plus: 2 }}",
    "want": "12",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "integer value and negative integer arg",
    "template": "{{ 10 | plus: -2 }}",
    "want": "8",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "not a string, int or float",
    "template": "{{ a | plus: 1 }}",
    "want": "1",
    "context": {
      "a": {}
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "string not a number",
    "template": "{{ \"foo\" | plus: \"2.0\" }}",
    "want": "2.0",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "string value and string arg",
    "template": "{{ \"10.1\" | plus: \"2.2\" }}",
    "want": "12.3",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "too many args",
    "template": "{{ 5 | plus: 1, '5' }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "undefined argument",
    "template": "{{ 10 | plus: nosuchthing }}",
    "want": "10",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined left value",
    "template": "{{ nosuchthing | plus: 2 }}",
    "want": "2",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]