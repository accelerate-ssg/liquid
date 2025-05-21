[
  {
    "name": "argument not a string",
    "template": "{{ \"hello5\" | replace_last: 5, \"your\" }}",
    "want": "helloyour",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "missing argument",
    "template": "{{ \"hello\" | replace_last: \"ll\" }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "missing arguments",
    "template": "{{ \"hello\" | replace_last }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "not a string",
    "template": "{{ 5 | replace_last: 'rain', 'foo' }}",
    "want": "5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "replace substrings",
    "template": "{{ \"Take my protein pills and put my helmet on\" | replace_last: \"my\", \"your\" }}",
    "want": "Take my protein pills and put your helmet on",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "too many arguments",
    "template": "{{ \"hello\" | replace_last: \"how\", \"are\", \"you\" }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "undefined first argument",
    "template": "{{ \"Take my protein\" | replace_last: nosuchthing, \"#\" }}",
    "want": "Take my protein#",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined left value",
    "template": "{{ nosuchthing | replace_last: \"my\", \"your\" }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined second argument",
    "template": "{{ \"Take my protein pills and put my helmet on\" | replace_last: \"my\", nosuchthing }}",
    "want": "Take my protein pills and put  helmet on",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]