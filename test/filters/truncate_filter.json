[
  {
    "name": "custom end",
    "template": "{{ \"Ground control to Major Tom.\" | truncate: 25, \", and so on\" }}",
    "want": "Ground control, and so on",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "default end",
    "template": "{{ \"Ground control to Major Tom.\" | truncate: 20 }}",
    "want": "Ground control to...",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "default length is 50",
    "template": "{{ \"Ground control to Major Tom. Ground control to Major Tom.\" | truncate }}",
    "want": "Ground control to Major Tom. Ground control to ...",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "no end",
    "template": "{{ \"Ground control to Major Tom.\" | truncate: 20, \"\" }}",
    "want": "Ground control to Ma",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "not a string",
    "template": "{{ 5 | truncate: 10 }}",
    "want": "5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "string is shorter than length",
    "template": "{{ \"Ground control\" | truncate: 20 }}",
    "want": "Ground control",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "too many arguments",
    "template": "{{ \"hello\" | truncate: 5, \"foo\", \"bar\" }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "undefined first argument",
    "template": "{{ \"Ground control to Major Tom.\" | truncate: nosuchthing }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "undefined left value",
    "template": "{{ nosuchthing | truncate: 5 }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined second argument",
    "template": "{{ \"Ground control to Major Tom.\" | truncate: 20, nosuchthing }}",
    "want": "Ground control to Ma",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]