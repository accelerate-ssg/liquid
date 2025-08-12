[
  {
    "name": "left and right padded",
    "template": "{{ \" \t\r\n  hello  \t\r\n \" | lstrip }}",
    "want": "hello  \t\r\n ",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "left padded",
    "template": "{{ \" \t\r\n  hello\" | lstrip }}",
    "want": "hello",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "not a string",
    "template": "{{ 5 | lstrip }}",
    "want": "5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "right padded",
    "template": "{{ \"hello \t\r\n  \" | lstrip }}",
    "want": "hello \t\r\n  ",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined left value",
    "template": "{{ nosuchthing | lstrip }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "unexpected argument",
    "template": "{{ \"hello\" | lstrip: 5 }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  }
]