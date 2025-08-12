[
  {
    "name": "argument not a string",
    "template": "{{ \"hello5\" | replace_first: 5, \"your\" }}",
    "want": "helloyour",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "missing argument",
    "template": "{{ \"hello\" | replace_first: \"ll\" }}",
    "want": "heo",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "missing arguments",
    "template": "{{ \"hello\" | replace_first }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "not a string",
    "template": "{{ 5 | replace_first: 'rain', 'foo' }}",
    "want": "5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "replace substrings",
    "template": "{{ \"Take my protein pills and put my helmet on\" | replace_first: \"my\", \"your\" }}",
    "want": "Take your protein pills and put my helmet on",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "too many arguments",
    "template": "{{ \"hello\" | replace_first: \"how\", \"are\", \"you\" }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "undefined first argument",
    "template": "{{ \"Take my protein\" | replace_first: nosuchthing, \"#\" }}",
    "want": "#Take my protein",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined left value",
    "template": "{{ nosuchthing | replace_first: \"my\", \"your\" }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined second argument",
    "template": "{{ \"Take my protein pills and put my helmet on\" | replace_first: \"my\", nosuchthing }}",
    "want": "Take  protein pills and put my helmet on",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]