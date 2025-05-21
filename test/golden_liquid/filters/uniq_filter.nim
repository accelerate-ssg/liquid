[
  {
    "name": "array of objects with key property",
    "template": "{% assign x = a | uniq: 'title' %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}",
    "want": "(title,foo)(name,a)(title,bar)(name,c)",
    "context": {
      "a": [
        {
          "title": "foo",
          "name": "a"
        },
        {
          "title": "foo",
          "name": "b"
        },
        {
          "title": "bar",
          "name": "c"
        }
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "array of objects with missing key property",
    "template": "{% assign x = a | uniq: 'title' %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}",
    "want": "(title,foo)(name,a)(title,bar)(name,c)(heading,bar)(name,c)",
    "context": {
      "a": [
        {
          "title": "foo",
          "name": "a"
        },
        {
          "title": "foo",
          "name": "b"
        },
        {
          "title": "bar",
          "name": "c"
        },
        {
          "heading": "bar",
          "name": "c"
        },
        {
          "heading": "baz",
          "name": "d"
        }
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "array of strings",
    "template": "{{ a | uniq | join: '#' }}",
    "want": "a#b",
    "context": {
      "a": [
        "a",
        "b",
        "b",
        "a"
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "array of things",
    "template": "{{ a | uniq | join: '#' }}",
    "want": "a#b#1",
    "context": {
      "a": [
        "a",
        "b",
        1,
        1
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "empty array",
    "template": "{{ a | uniq | join: '#' }}",
    "want": "",
    "context": {
      "a": []
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "left value is not an array",
    "template": "{{ a | uniq | join: '#' }}",
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
    "template": "{{ nosuchthing | uniq | join: '#' }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "too many arguments",
    "template": "{{ nosuchthing | uniq: 'foo', 'bar' }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "unhashable items",
    "template": "{{ a | uniq | join: '#' }}",
    "want": "a#b#{}",
    "context": {
      "a": [
        "a",
        "b",
        [],
        {},
        {}
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  }
]