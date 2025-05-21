[
  {
    "name": "argument not a string",
    "template": "{{ \"hello\" | replace: 5, \"your\" }}",
    "want": "hello",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "left value is an object",
    "template": "{{ a | replace: '{', '!' }}",
    "want": "!}",
    "context": {
      "a": {}
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "missing argument",
    "template": "{{ \"hello\" | replace: \"ll\" }}",
    "want": "heo",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "missing arguments",
    "template": "{{ \"hello\" | replace }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "not a string",
    "template": "{{ 5 | replace: 'rain', 'foo' }}",
    "want": "5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "replace substrings",
    "template": "{{ \"Take my protein pills and put my helmet on\" | replace: \"my\", \"your\" }}",
    "want": "Take your protein pills and put your helmet on",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "too many arguments",
    "template": "{{ \"hello\" | replace: \"how\", \"are\", \"you\" }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "undefined first argument",
    "template": "{{ \"Take my protein\" | replace: nosuchthing, \"#\" }}",
    "want": "#T#a#k#e# #m#y# #p#r#o#t#e#i#n#",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined left value",
    "template": "{{ nosuchthing | replace: \"my\", \"your\" }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined second argument",
    "template": "{{ \"Take my protein pills and put my helmet on\" | replace: \"my\", nosuchthing }}",
    "want": "Take  protein pills and put  helmet on",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]