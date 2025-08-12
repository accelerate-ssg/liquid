[
  {
    "name": "not a string",
    "template": "{{ 5 | url_decode }}",
    "want": "5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "some special URL characters",
    "template": "{{ \"email+address+is+bob%40example.com%21\" | url_decode }}",
    "want": "email address is bob@example.com!",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined left value",
    "template": "{{ nosuchthing | url_decode }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "unexpected argument",
    "template": "{{ \"hello\" | url_decode: 5 }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  }
]