[
  {
    "name": "array of strings",
    "template": "{{ arr | first }}",
    "want": "a",
    "context": {
      "arr": [
        "a",
        "b"
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "array of things",
    "template": "{{ arr | first }}",
    "want": "a",
    "context": {
      "arr": [
        "a",
        "b",
        1,
        [],
        {}
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "empty left value",
    "template": "{{ arr | first }}",
    "want": "",
    "context": {
      "arr": []
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "first of a hash",
    "template": "{% assign x = a | first %}({{ x[0] }},{{ x[1] }})",
    "want": "(b,1)",
    "context": {
      "a": {
        "b": 1,
        "c": 2
      }
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "first of a string",
    "template": "{{ 'hello' | first }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "left value is not an array",
    "template": "{{ arr | first }}",
    "want": "",
    "context": {
      "arr": 12
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "left value is undefined",
    "template": "{{ nosuchthing | first }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "range literal first filter left value",
    "template": "{{ (1..3) | first }}",
    "want": "1",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]