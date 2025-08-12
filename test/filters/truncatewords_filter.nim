[
  {
    "name": "all whitespace is clobbered",
    "template": "{{ \"    one    two three    four  \" | truncatewords: 2 }}",
    "want": "one two...",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "custom end",
    "template": "{{ \"Ground control to Major Tom.\" | truncatewords: 3, \"--\" }}",
    "want": "Ground control to--",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "default end",
    "template": "{{ \"Ground control to Major Tom.\" | truncatewords: 3 }}",
    "want": "Ground control to...",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "fewer words than word count",
    "template": "{{ \"Ground control\" | truncatewords: 3 }}",
    "want": "Ground control",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "no end",
    "template": "{{ \"Ground control to Major Tom.\" | truncatewords: 3, \"\" }}",
    "want": "Ground control to",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "not a string",
    "template": "{{ 5 | truncatewords: 10 }}",
    "want": "5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "number of words defaults to 15",
    "template": "{{ \"a b c d e f g h i j k l m n o p q\" | truncatewords }}",
    "want": "a b c d e f g h i j k l m n o...",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "reference implementation test 1",
    "template": "{{ \"测试测试测试测试\" | truncatewords: 5 }}",
    "want": "测试测试测试测试",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "reference implementation test 2",
    "template": "{{ \"one two three\" | truncatewords: 2, 1 }}",
    "want": "one two1",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "reference implementation test 3",
    "template": "{{ \"one  two\tthree\nfour\" | truncatewords: 3 }}",
    "want": "one two three...",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "reference implementation test 4",
    "template": "{{ \"one two three four\" | truncatewords: 2 }}",
    "want": "one two...",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "reference implementation test 5",
    "template": "{{ \"one two three four\" | truncatewords: 0 }}",
    "want": "one...",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "too many arguments",
    "template": "{{ \"hello\" | truncatewords: 5, \"foo\", \"bar\" }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "undefined first argument",
    "template": "{{ \"one two three four\" | truncatewords: nosuchthing }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "undefined left value",
    "template": "{{ nosuchthing | truncatewords: 5 }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined second argument",
    "template": "{{ \"one two three four\" | truncatewords: 2, nosuchthing }}",
    "want": "one two",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]