[
  {
    "name": "first argument is a float",
    "template": "{{ 'Liquid' | slice: 2.2 }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "first argument is a string",
    "template": "{{ \"hello\" | slice: \"2\" }}",
    "want": "l",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "first argument not an integer",
    "template": "{{ \"hello\" | slice: \"foo\" }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "missing arguments",
    "template": "{{ \"hello\" | slice }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "negative first argument",
    "template": "{{ 'Liquid' | slice: -2 }}",
    "want": "i",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "negative first argument and length out of range",
    "template": "{{ 'Liquid' | slice: -2, 99 }}",
    "want": "id",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "negative first argument and negative length",
    "template": "{{ 'Liquid' | slice: -2, -1 }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "negative first argument and positive length",
    "template": "{{ 'Liquid' | slice: -2, 2 }}",
    "want": "id",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "not a string",
    "template": "{{ 5 | slice: 1 }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "one",
    "template": "{{ \"hello\" | slice: 1 }}",
    "want": "e",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "one length three",
    "template": "{{ \"hello\" | slice: 1, 3 }}",
    "want": "ell",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "out of range",
    "template": "{{ \"hello\" | slice: 99 }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "second argument is a float",
    "template": "{{ 'Liquid' | slice: 1, 2.2 }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "second argument is a string",
    "template": "{{ \"hello\" | slice: 3, \"2\" }}",
    "want": "lo",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "second argument not an integer",
    "template": "{{ \"hello\" | slice: 5, \"foo\" }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "slice an array of numbers",
    "template": "{{ a | slice: 2, 3 | join: '#' }}",
    "want": "3#4#5",
    "context": {
      "a": [
        1,
        2,
        3,
        4,
        5
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "too many arguments",
    "template": "{{ \"hello\" | slice: 1, 2, 3 }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "undefined first argument",
    "template": "{{ \"hello\" | slice: nosuchthing, 3 }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "undefined left value",
    "template": "{{ nosuchthing | slice: 1, 3 }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined second argument",
    "template": "{{ \"hello\" | slice: 1, nosuchthing }}",
    "want": "e",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "zero",
    "template": "{{ \"hello\" | slice: 0 }}",
    "want": "h",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]