[
  {
    "name": "size of a hash",
    "template": "{{ a | size }}",
    "want": "2",
    "context": {
      "a": {
        "a": 1,
        "b": 2
      }
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "size of a string",
    "template": "{{ a | size }}",
    "want": "3",
    "context": {
      "a": "abc"
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "size of an array",
    "template": "{{ a | size }}",
    "want": "3",
    "context": {
      "a": [
        "a",
        "b",
        "c"
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "size of an empty array",
    "template": "{{ a | size }}",
    "want": "0",
    "context": {
      "a": []
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined left value",
    "template": "{{ nosuchthing | size }}",
    "want": "0",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "unexpected argument",
    "template": "{{ a | size: 'foo' }}",
    "want": "",
    "context": {
      "a": [
        1,
        2,
        3
      ]
    },
    "partials": {},
    "error": true,
    "strict": false
  }
]