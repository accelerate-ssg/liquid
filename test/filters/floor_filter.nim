[
  {
    "name": "negative float",
    "template": "{{ -5.4 | floor }}",
    "want": "-6",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "negative integer",
    "template": "{{ -5 | floor }}",
    "want": "-5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "negative string float",
    "template": "{{ \"-5.1\" | floor }}",
    "want": "-6",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "not a string, int or float",
    "template": "{{ a | floor }}",
    "want": "0",
    "context": {
      "a": {}
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "positive float",
    "template": "{{ 5.4 | floor }}",
    "want": "5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "positive integer",
    "template": "{{ 5 | floor }}",
    "want": "5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "positive string float",
    "template": "{{ \"5.1\" | floor }}",
    "want": "5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "string not a number",
    "template": "{{ \"hello\" | floor }}",
    "want": "0",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined left value",
    "template": "{{ nosuchthing | floor }}",
    "want": "0",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "unexpected argument",
    "template": "{{ -3.1 | floor: 1 }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "zero",
    "template": "{{ 0 | floor }}",
    "want": "0",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]