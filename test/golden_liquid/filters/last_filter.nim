[
  {
    "name": "array of strings",
    "template": "{{ arr | last }}",
    "want": "b",
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
    "template": "{{ arr | last }}",
    "want": "{}",
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
    "name": "empty array",
    "template": "{{ arr | last }}",
    "want": "",
    "context": {
      "arr": []
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "last of a hash",
    "template": "{{ a | last }}",
    "want": "",
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
    "name": "last of a string",
    "template": "{{ 'hello' | last }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "left value is undefined",
    "template": "{{ nosuchthing | last }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "left value not an array",
    "template": "{{ arr | last }}",
    "want": "",
    "context": {
      "arr": 12
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "range literal last filter left value",
    "template": "{{ (1..3) | last }}",
    "want": "3",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]