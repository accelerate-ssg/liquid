[
  {
    "name": "argument is undefined",
    "template": "{% assign x = a | sort_natural: nosuchthing %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}",
    "want": "(title,bar)(title,Baz)(title,foo)",
    "context": {
      "a": [
        {
          "title": "foo"
        },
        {
          "title": "bar"
        },
        {
          "title": "Baz"
        }
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "array of objects with a key",
    "template": "{% assign x = a | sort_natural: 'title' %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}",
    "want": "(title,bar)(title,Baz)(title,foo)",
    "context": {
      "a": [
        {
          "title": "foo"
        },
        {
          "title": "bar"
        },
        {
          "title": "Baz"
        }
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "array of objects with a key gets stringified",
    "template": "{% assign x = a | sort_natural: 'title' %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}",
    "want": "(title,1111)(title,87)(title,9)",
    "context": {
      "a": [
        {
          "title": 9
        },
        {
          "title": 1111
        },
        {
          "title": 87
        }
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "array of objects with a missing key",
    "template": "{% assign x = a | sort_natural: 'title' %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}",
    "want": "(title,bar)(title,foo)(heading,Baz)",
    "context": {
      "a": [
        {
          "title": "foo"
        },
        {
          "title": "bar"
        },
        {
          "heading": "Baz"
        }
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "array of strings",
    "template": "{{ a | sort_natural | join: '#' }}",
    "want": "a#A#b#B#C",
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
    "name": "array of strings with a nul",
    "template": "{% assign x = a | sort_natural %}{% for i in x %}{{ i }}{% unless forloop.last %}#{% endunless %}{% endfor %}",
    "want": "a#A#b#B#C#",
    "context": {
      "a": [
        "b",
        "a",
        null,
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
    "template": "{% assign x = a | sort_natural %}{% for i in x %}{{ i }}{% unless forloop.last %}#{% endunless %}{% endfor %}",
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
    "template": "{{ a | sort_natural }}",
    "want": "14{}",
    "context": {
      "a": [
        {},
        1,
        "4"
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "left value is not an array",
    "template": "{{ a | sort_natural }}",
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
    "template": "{{ nosuchthing | sort_natural }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]