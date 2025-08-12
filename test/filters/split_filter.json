[
  {
    "name": "argument does not appear in string",
    "template": "{% assign a = \"abc\" | split: \",\" %}{% for i in a %}#{{ forloop.index0 }}{{ i }}{% endfor %}",
    "want": "#0abc",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "argument not a string",
    "template": "{{ \"hello th1ere\" | split: 1 | join: \"#\" }}",
    "want": "hello th#ere",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "empty string and empty argument",
    "template": "{% assign a = \"\" | split: \"\" %}{% for i in a %}{{ forloop.index0 }}{{ i }}{% endfor %}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "empty string and single char argument",
    "template": "{% assign a = \"\" | split: \",\" %}{% for i in a %}{{ forloop.index0 }}{{ i }}{% endfor %}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "empty string argument",
    "template": "{% assign a = \"abc\" | split: \"\" %}{% for i in a %}#{{ forloop.index0 }}{{ i }}{% endfor %}",
    "want": "#0a#1b#2c",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "left matches argument",
    "template": "{% assign a = \",\" | split: \",\" %}{% for i in a %}{{ forloop.index0 }}{{ i }}{% endfor %}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "left matches string repr of argument",
    "template": "{% assign a = \"1\" | split: 1 %}{% for i in a %}{{ forloop.index0 }}{{ i }}{% endfor %}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "missing argument",
    "template": "{{ \"hello there\" | split }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "not a string",
    "template": "{{ 56 | split: ' ' | first }}",
    "want": "56",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "split string",
    "template": "{{ \"Hi, how are you today?\" | split: \" \" | join: \"#\" }}",
    "want": "Hi,#how#are#you#today?",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "too many arguments",
    "template": "{{ \"hello there\" | split: \" \", \",\" }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "undefined argument",
    "template": "{{ \"Hello there\" | split: nosuchthing | join: \"#\" }}",
    "want": "H#e#l#l#o# #t#h#e#r#e",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined left value",
    "template": "{{ nosuchthing | split: \" \" }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]