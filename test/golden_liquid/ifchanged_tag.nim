[
  {
    "name": "change from assign",
    "template": "{% assign foo = 'hello' %}{% ifchanged %}{{ foo }}{% endifchanged %}{% ifchanged %}{{ foo }}{% endifchanged %}{% assign foo = 'goodbye' %}{% ifchanged %}{{ foo }}{% endifchanged %}",
    "want": "hellogoodbye",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "changed from initial state",
    "template": "{% ifchanged %}hello{% endifchanged %}",
    "want": "hello",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "no change from assign",
    "template": "{% assign foo = 'hello' %}{% ifchanged %}{{ foo }}{% endifchanged %}{% ifchanged %}{{ foo }}{% endifchanged %}",
    "want": "hello",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "not changed from initial state",
    "template": "{% ifchanged %}{% endifchanged %}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "within for loop",
    "template": "{% assign list = \"1,3,2,1,3,1,2\" | split: \",\" | sort %}{% for item in list -%}{%- ifchanged %} {{ item }}{% endifchanged -%}{%- endfor %}",
    "want": " 1 2 3",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]