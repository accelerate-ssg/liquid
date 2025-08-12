[
  {
    "name": "arg string not a number",
    "template": "{{ \"10\" | modulo: \"foo\" }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "float value and float arg",
    "template": "{{ 10.1 | modulo: 7.0 }}",
    "want": "3.1",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "integer value and float arg",
    "template": "{{ 10 | modulo: 2.0 }}",
    "want": "0.0",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "integer value and integer arg",
    "template": "{{ 10 | modulo: 2 }}",
    "want": "0",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "not a string, int or float",
    "template": "{{ a | modulo: 1 }}",
    "want": "0",
    "context": {
      "a": {}
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "string not a number",
    "template": "{{ \"foo\" | modulo: \"2.0\" }}",
    "want": "0.0",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "string value and argument",
    "template": "{{ \"10\" | modulo: \"2.0\" }}",
    "want": "0.0",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "too many args",
    "template": "{{ 5 | modulo: 1, '5' }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "undefined argument",
    "template": "{{ 5 | modulo: nosuchthing }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "undefined left value",
    "template": "{{ nosuchthing | modulo: 2 }}",
    "want": "0",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]