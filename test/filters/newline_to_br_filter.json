[
  {
    "name": "not a string",
    "template": "{{ 5 | newline_to_br }}",
    "want": "5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "reference implementation test 1",
    "template": "{{ \"a\nb\nc\" | newline_to_br }}",
    "want": "a<br />\nb<br />\nc",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "reference implementation test 2",
    "template": "{{ \"a\r\nb\nc\" | newline_to_br }}",
    "want": "a<br />\nb<br />\nc",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "string with newlines",
    "template": "{{ \"- apples\n- oranges\n\" | newline_to_br }}",
    "want": "- apples<br />\n- oranges<br />\n",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined left value",
    "template": "{{ nosuchthing | newline_to_br }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "unexpected argument",
    "template": "{{ \"hello\" | newline_to_br: 5 }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  }
]