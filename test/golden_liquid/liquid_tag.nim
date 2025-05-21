[
  {
    "name": "bare liquid tag in liquid tag",
    "template": "{%- liquid\n  liquid\n  echo \"foo\"\n-%}",
    "want": "foo",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "can't close nested blocks",
    "template": "{%- if true -%}\n42\n{%- liquid endif -%}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "carriage return and newline terminated tags",
    "template": "{% liquid\r\nif product.title\r\n   echo product.title | upcase\r\nelse\r\n   echo 'product-1' | upcase \r\nendif\r\n\r\nfor i in (0..5)\r\n   echo i\r\nendfor %}",
    "want": "FOO012345",
    "context": {
      "product": {
        "title": "foo"
      }
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "carriage return terminated tags",
    "template": "{% liquid\rif product.title\r   echo product.title | upcase\relse\r   echo 'product-1' | upcase \rendif\r\rfor i in (0..5)\r   echo i\rendfor %}",
    "want": "",
    "context": {
      "product": {
        "title": "foo"
      }
    },
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "empty liquid tag",
    "template": "{% liquid %}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "liquid tag in liquid tag",
    "template": "{%- liquid\n  liquid echo 'bar'\n  echo \"foo\"\n-%}",
    "want": "barfoo",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "multi-line comment tag",
    "template": "{% liquid\ncomment this is a comment\nsplit over two lines\nendcomment\n%}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "nested liquid",
    "template": "{%- if true %}\n  {%- liquid\n    echo \"good\"\n  %}\n{%- endif -%}",
    "want": "good",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "nested liquid in liquid tag",
    "template": "{%- liquid liquid liquid echo \"foo\" -%}",
    "want": "foo",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "newline terminated tags",
    "template": "{% liquid\nif product.title\n   echo product.title | upcase\nelse\n   echo 'product-1' | upcase \nendif\n\nfor i in (0..5)\n   echo i\nendfor %}",
    "want": "FOO012345",
    "context": {
      "product": {
        "title": "foo"
      }
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "only whitespace",
    "template": "{% liquid\n   \n\n   \t \n\t\n  %}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "reference test #2",
    "template": "{%- liquid\n  for value in array\n    echo value\n    unless forloop.last\n      echo '#'\n    endunless\n  endfor\n-%}",
    "want": "1#2#3",
    "context": {
      "array": [
        1,
        2,
        3
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "reference test #3",
    "template": "{%- liquid\n  for value in array\n    assign double_value = value | times: 2\n    echo double_value | times: 2\n    unless forloop.last\n      echo '#'\n    endunless\n  endfor\n\n  echo '#'\n  echo double_value\n-%}",
    "want": "4#8#12#6",
    "context": {
      "array": [
        1,
        2,
        3
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "reference test #4",
    "template": "{%- liquid echo 'a' -%}\nb\n{%- liquid echo 'c' -%}",
    "want": "abc",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "single line comment tag",
    "template": "{% liquid\ncomment this is a comment\nendcomment\n%}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "whitespace control",
    "template": "Hello,     \n{%- liquid\n  echo ' World! '\n-%}\n   Goodbye.",
    "want": "Hello, World! Goodbye.",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]