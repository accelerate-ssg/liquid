[
  {
    "name": "float times float",
    "template": "{{ 5.0 | times: 2.1 }}",
    "want": "10.5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "int times float",
    "template": "{{ 5 | times: 2.1 }}",
    "want": "10.5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "int times int",
    "template": "{{ 5 | times: 2 }}",
    "want": "10",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "missing arg",
    "template": "{{ 5 | times }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "negative multiplication",
    "template": "{{ -5 | times: 2 }}",
    "want": "-10",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "string times string",
    "template": "{{ \"5.0\" | times: \"2.1\" }}",
    "want": "10.5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "too many args",
    "template": "{{ 5 | times: 1, 2 }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "undefined argument",
    "template": "{{ 5 | times: nosuchthing }}",
    "want": "0",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined left value",
    "template": "{{ nosuchthing | times: 2 }}",
    "want": "0",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]