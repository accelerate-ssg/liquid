[
  {
    "name": "make HTML-safe",
    "template": "{{ \"&lt;p&gt;test&lt;/p&gt;\" | escape_once }}",
    "want": "&lt;p&gt;test&lt;/p&gt;",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "make HTML-safe from mixed safe and markup.",
    "template": "{{ \"&lt;p&gt;test&lt;/p&gt;<p>test</p>\" | escape_once }}",
    "want": "&lt;p&gt;test&lt;/p&gt;&lt;p&gt;test&lt;/p&gt;",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "not a string",
    "template": "{{ 5 | escape_once }}",
    "want": "5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined left value",
    "template": "{{ nosuchthing | escape_once }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "unexpected argument",
    "template": "{{ \"HELLO\" | escape_once: 5 }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  }
]