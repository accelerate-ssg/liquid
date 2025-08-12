[
  {
    "name": "make HTML-safe",
    "template": "{{ \"<p>test</p>\" | escape }}",
    "want": "&lt;p&gt;test&lt;/p&gt;",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "not a string",
    "template": "{{ 5 | escape }}",
    "want": "5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined left value",
    "template": "{{ nosuchthing | escape }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "unexpected argument",
    "template": "{{ \"HELLO\" | escape: 5 }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  }
]