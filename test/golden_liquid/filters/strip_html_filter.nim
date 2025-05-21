[
  {
    "name": "html block",
    "template": "{{ s | strip_html }}",
    "want": "test",
    "context": {
      "s": "<div>test</div>"
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "html block with id",
    "template": "{{ s | strip_html }}",
    "want": "test",
    "context": {
      "s": "<div id='test'>test</div>"
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "html block with newline",
    "template": "{{ s | strip_html }}",
    "want": "test",
    "context": {
      "s": "<div\nclass='multiline'>test</div>"
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "html comment with newline",
    "template": "{{ s | strip_html }}",
    "want": "test",
    "context": {
      "s": "<!-- foo bar \n test -->test"
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "not a string",
    "template": "{{ 5 | strip_html }}",
    "want": "5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "script block",
    "template": "{{ s | strip_html }}",
    "want": "",
    "context": {
      "s": "<script type='text/javascript'>document.write('some stuff');</script>"
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "some HTML markup",
    "template": "{{ s | strip_html }}",
    "want": "Have you read Ulysses &amp; &#20;?",
    "context": {
      "s": "Have <em>you</em> read <strong>Ulysses</strong> &amp; &#20;?"
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "some HTML markup with HTML comment",
    "template": "{{ s | strip_html }}",
    "want": "you read Ulysses &amp; &#20;?",
    "context": {
      "s": "<!-- Have --><em>you</em> read <strong>Ulysses</strong> &amp; &#20;?"
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "style block",
    "template": "{{ s | strip_html }}",
    "want": "",
    "context": {
      "s": "<style type='text/css'>foo bar</style>"
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined left value",
    "template": "{{ nosuchthing | strip_html }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "unexpected argument",
    "template": "{{ \"hello\" | strip_html: 5 }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  }
]