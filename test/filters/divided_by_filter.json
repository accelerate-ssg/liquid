[
  {
    "name": "arg string not a number",
    "template": "{{ \"10\" | divided_by: \"foo\" }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "divied by zero",
    "template": "{{ 10 | divided_by: 0 }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "float division",
    "template": "{{ 20 | divided_by: 7.0 }}",
    "want": "2.857142857142857",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "float value and integer arg",
    "template": "{{ 9.0 | divided_by: 2 }}",
    "want": "4.5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "integer division",
    "template": "{{ 9 | divided_by: 2 }}",
    "want": "4",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "integer value and float arg",
    "template": "{{ 10 | divided_by: 2.0 }}",
    "want": "5.0",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "integer value and integer arg",
    "template": "{{ 10 | divided_by: 2 }}",
    "want": "5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "issue",
    "template": "{{ 5 | divided_by: 3 }}",
    "want": "1",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "left value is an empty string",
    "template": "{{ '' | divided_by: 2 }}",
    "want": "0",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "not a string, int or float",
    "template": "{{ a | divided_by: 1 }}",
    "want": "0",
    "context": {
      "a": {}
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "render",
    "template": "{{ 5.0 }} {{ 5 }}",
    "want": "5.0 5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "string not a number",
    "template": "{{ \"foo\" | divided_by: \"2\" }}",
    "want": "0",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "string value and argument",
    "template": "{{ \"10\" | divided_by: \"2\" }}",
    "want": "5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "too many args",
    "template": "{{ 5 | divided_by: 1, '5' }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "undefined argument",
    "template": "{{ 10 | divided_by: nosuchthing }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "undefined left value",
    "template": "{{ nosuchthing | divided_by: 2 }}",
    "want": "0",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "zero divided by float",
    "template": "{{ 0 | divided_by: 1.1 }}",
    "want": "0.0",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "zero divided by integer",
    "template": "{{ 0 | divided_by: 1 }}",
    "want": "0",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]