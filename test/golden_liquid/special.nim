[
  {
    "name": "first of a string",
    "template": "{{ s.first }}",
    "want": "",
    "context": {
      "s": "hello"
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "first of an array",
    "template": "{{ a.first }}",
    "want": "3",
    "context": {
      "a": [
        3,
        2,
        1
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "first of an empty object",
    "template": "{{ obj.first | join: '#' }}",
    "want": "",
    "context": {
      "obj": {}
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "first of an object",
    "template": "{{ obj.first | join: '#' }}",
    "want": "a#1",
    "context": {
      "obj": {
        "a": 1,
        "b": 2
      }
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "first of an object with a first property",
    "template": "{{ obj.first }}",
    "want": "99",
    "context": {
      "obj": {
        "a": 1,
        "first": 99
      }
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "last of a object",
    "template": "{{ obj.last }}",
    "want": "",
    "context": {
      "obj": {
        "a": 1,
        "b": 2
      }
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "last of a string",
    "template": "{{ s.last }}",
    "want": "",
    "context": {
      "s": "hello"
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "last of an array",
    "template": "{{ a.last }}",
    "want": "1",
    "context": {
      "a": [
        3,
        2,
        1
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "last of an object with a last property",
    "template": "{{ obj.last }}",
    "want": "99",
    "context": {
      "obj": {
        "a": 1,
        "last": 99,
        "b": 42
      }
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "size of a string",
    "template": "{{ s.size }}",
    "want": "5",
    "context": {
      "s": "hello"
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "size of an array",
    "template": "{{ a.size }}",
    "want": "3",
    "context": {
      "a": [
        3,
        2,
        1
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "size of an object with a size property",
    "template": "{{ obj.size }}",
    "want": "99",
    "context": {
      "obj": {
        "size": 99
      }
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "size of undefined",
    "template": "{{ nosuchthing.last }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]