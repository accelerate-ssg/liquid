[
  {
    "name": "argument is undefined",
    "template": "{{ a | sort: nosuchthing | join: '#' }}",
    "want": "a#b",
    "context": {
      "a": [
        "b",
        "a"
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "array of integers",
    "template": "{{ a | sort | join: '#' }}",
    "want": "1#3#30#1000",
    "context": {
      "a": [
        1,
        1000,
        3,
        30
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "array of objects",
    "template": "{% assign x = a | sort: 'title' %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}",
    "want": "(title,Baz)(title,bar)(title,foo)",
    "context": {
      "a": [
        {
          "title": "foo"
        },
        {
          "title": "Baz"
        },
        {
          "title": "bar"
        }
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "array of objects with missing key",
    "template": "{% assign x = a | sort: 'title' %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}",
    "want": "(title,bar)(title,foo)(heading,Baz)",
    "context": {
      "a": [
        {
          "title": "foo"
        },
        {
          "heading": "Baz"
        },
        {
          "title": "bar"
        }
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "array of strings",
    "template": "{{ a | sort | join: '#' }}",
    "want": "A#B#C#a#b",
    "context": {
      "a": [
        "b",
        "a",
        "C",
        "B",
        "A"
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "empty array",
    "template": "{{ a | sort | join: '#' }}",
    "want": "",
    "context": {
      "a": []
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "incompatible types",
    "template": "{{ a | sort }}",
    "want": "",
    "context": {
      "a": [
        [],
        {},
        1,
        "4"
      ]
    },
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "left value is not an array",
    "template": "{{ a | sort | join: '#' }}",
    "want": "123",
    "context": {
      "a": 123
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "left value is undefined",
    "template": "{{ nosuchthing | sort | join: '#' }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "sort a string",
    "template": "{{ 'BzAa4' | sort | join: '#' }}",
    "want": "BzAa4",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "too many arguments",
    "template": "{{ a | sort: 'title', 'foo' | join: '#' }}",
    "want": "",
    "context": {
      "a": [
        "b",
        "a"
      ]
    },
    "partials": {},
    "error": true,
    "strict": false
  }
]