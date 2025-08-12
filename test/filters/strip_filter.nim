[
  {
    "name": "left and right padded",
    "template": "{{ \" \t\r\n  hello  \t\r\n \" | strip }}",
    "want": "hello",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "left padded",
    "template": "{{ \" \t\r\n  hello\" | strip }}",
    "want": "hello",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "not a string",
    "template": "{{ 5 | strip }}",
    "want": "5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "right padded",
    "template": "{{ \"hello \t\r\n  \" | strip }}",
    "want": "hello",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined left value",
    "template": "{{ nosuchthing | strip }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "unexpected argument",
    "template": "{{ \"hello\" | strip: 5 }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  }
]