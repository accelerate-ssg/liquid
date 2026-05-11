[
  {
    "name": "argument not a string",
    "template": "{{ \"hello\" | prepend: 5 }}",
    "want": "5hello",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "concat",
    "template": "{{ \"hello\" | prepend: \"there\" }}",
    "want": "therehello",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "missing argument",
    "template": "{{ \"hello\" | prepend }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "not a string",
    "template": "{{ 5 | prepend: 'there' }}",
    "want": "there5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "too many arguments",
    "template": "{{ \"hello\" | prepend: \"how\", \"are\", \"you\" }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "undefined argument",
    "template": "{{ \"hi\" | prepend: nosuchthing }}",
    "want": "hi",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined left value",
    "template": "{{ nosuchthing | prepend: \"hi\" }}",
    "want": "hi",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]