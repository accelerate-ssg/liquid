[
  {
    "name": "newline and other whitespace",
    "template": "{{ \"hello there\nyou\" | strip_newlines }}",
    "want": "hello thereyou",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "not a string",
    "template": "{{ 5 | strip_newlines }}",
    "want": "5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "reference implementation test 1",
    "template": "{{ \"a\nb\nc\" | strip_newlines }}",
    "want": "abc",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "reference implementation test 2",
    "template": "{{ \"a\r\nb\nc\" | strip_newlines }}",
    "want": "abc",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined left value",
    "template": "{{ nosuchthing | strip_newlines }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "unexpected argument",
    "template": "{{ \"hello\" | strip_newlines: 5 }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  }
]