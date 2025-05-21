[
  {
    "name": "left and right padded",
    "template": "{{ \" \t\r\n  hello  \t\r\n \" | rstrip }}",
    "want": " \t\r\n  hello",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "left padded",
    "template": "{{ \" \t\r\n  hello\" | rstrip }}",
    "want": " \t\r\n  hello",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "not a string",
    "template": "{{ 5 | rstrip }}",
    "want": "5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "right padded",
    "template": "{{ \"hello \t\r\n  \" | rstrip }}",
    "want": "hello",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined left value",
    "template": "{{ nosuchthing | rstrip }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "unexpected argument",
    "template": "{{ \"hello\" | rstrip: 5 }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  }
]