[
  {
    "name": "argument not a string",
    "template": "{{ \"hello\" | remove_last: 5 }}",
    "want": "hello",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "missing argument",
    "template": "{{ \"hello\" | remove_last }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "not a string",
    "template": "{{ 5 | remove_last: 'rain' }}",
    "want": "5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "remove substrings",
    "template": "{{ \"I strained to see the train through the rain\" | remove_last: \"rain\" }}",
    "want": "I strained to see the train through the ",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "too many arguments",
    "template": "{{ \"hello\" | remove_last: \"how\", \"are\", \"you\" }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "undefined argument",
    "template": "{{ \"hello\" | remove_last: nosuchthing }}",
    "want": "hello",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined left value",
    "template": "{{ nosuchthing | remove_last: \"rain\" }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]