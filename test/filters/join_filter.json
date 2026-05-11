[
  {
    "name": "argument is not a string",
    "template": "{{ arr | join: 5 }}",
    "want": "a5b",
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
    "name": "join an array of integers",
    "template": "{{ arr | join: '#' }}",
    "want": "1#2",
    "context": {
      "arr": [
        1,
        2
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "join an array of strings",
    "template": "{{ arr | join: '#' }}",
    "want": "a#b",
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
    "name": "joining a string is a noop",
    "template": "{{ 'a,b' | join: '#' }}",
    "want": "a,b",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "joining an int is a noop",
    "template": "{{ 123 | join: '#' }}",
    "want": "123",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "left value contains non string",
    "template": "{{ arr | join: '#' }}",
    "want": "a#b#1",
    "context": {
      "arr": [
        "a",
        "b",
        1
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "missing argument defaults to a space",
    "template": "{{ arr | join }}",
    "want": "a b",
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
    "name": "range literal join filter left value",
    "template": "{{ (1..3) | join: '#' }}",
    "want": "1#2#3",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "too many arguments",
    "template": "{{ arr | join: '#', 42 }}",
    "want": "",
    "context": {
      "arr": [
        "a",
        "b"
      ]
    },
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "undefined argument",
    "template": "{{ arr | join: nosuchthing }}",
    "want": "ab",
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
    "name": "undefined left value",
    "template": "{{ nosuchthing | join: '#' }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]