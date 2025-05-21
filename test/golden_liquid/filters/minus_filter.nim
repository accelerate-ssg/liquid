[
  {
    "name": "arg string not a number",
    "template": "{{ \"10\" | minus: \"foo\" }}",
    "want": "10",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "float value and float arg",
    "template": "{{ 10.1 | minus: 2.2 }}",
    "want": "7.9",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "integer value and float arg",
    "template": "{{ 10 | minus: 2.0 }}",
    "want": "8.0",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "integer value and integer arg",
    "template": "{{ 10 | minus: 2 }}",
    "want": "8",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "not a string, int or float",
    "template": "{{ a | minus: 1 }}",
    "want": "-1",
    "context": {
      "a": {}
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "string not a number",
    "template": "{{ \"foo\" | minus: \"2.0\" }}",
    "want": "-2.0",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "string value and string arg",
    "template": "{{ \"10.1\" | minus: \"2.2\" }}",
    "want": "7.9",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "too many args",
    "template": "{{ 5 | minus: 1, '5' }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "undefined argument",
    "template": "{{ 10 | minus: nosuchthing }}",
    "want": "10",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined left value",
    "template": "{{ nosuchthing | minus: 2 }}",
    "want": "-2",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]