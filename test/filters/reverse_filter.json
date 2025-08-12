[
  {
    "name": "array of strings",
    "template": "{{ a | reverse | join: '#' }}",
    "want": "A#B#a#b",
    "context": {
      "a": [
        "b",
        "a",
        "B",
        "A"
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "array of things",
    "template": "{{ a | reverse | join: '#' }}",
    "want": "{}#1#b#a",
    "context": {
      "a": [
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
    "template": "{{ a | reverse | join: '#' }}",
    "want": "",
    "context": {
      "a": []
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "left value is undefined",
    "template": "{{ nosuchthing | reverse | join: '#' }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "left value not an array",
    "template": "{{ a | reverse | join: '#' }}",
    "want": "123",
    "context": {
      "a": 123
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "unexpected argument",
    "template": "{{ a | reverse: 0 | join: '#' }}",
    "want": "",
    "context": {
      "a": []
    },
    "partials": {},
    "error": true,
    "strict": false
  }
]