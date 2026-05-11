[
  {
    "name": "array containing a non object",
    "template": "{{ a | map: 'title' | join: '#' }}",
    "want": "",
    "context": {
      "a": [
        {
          "title": "foo"
        },
        {
          "title": "bar"
        },
        5,
        []
      ]
    },
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "array of objects",
    "template": "{{ a | map: 'title' | join: '#' }}",
    "want": "foo#bar#baz",
    "context": {
      "a": [
        {
          "title": "foo"
        },
        {
          "title": "bar"
        },
        {
          "title": "baz"
        }
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "input is a hash",
    "template": "{{ a | map: 'title' | join: '#' }}",
    "want": "foo",
    "context": {
      "a": {
        "title": "foo",
        "some": "thing"
      }
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "left value not an array",
    "template": "{{ a | map: 'title' | join: '#' }}",
    "want": "",
    "context": {
      "a": 123
    },
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "missing property",
    "template": "{{ a | map: 'title' | join: '#' }}",
    "want": "foo#bar#",
    "context": {
      "a": [
        {
          "title": "foo"
        },
        {
          "title": "bar"
        },
        {
          "heading": "baz"
        }
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "nested arrays get flattened",
    "template": "{{ a | map: 'title' | join: '#' }}",
    "want": "foo#bar#baz",
    "context": {
      "a": [
        {
          "title": "foo"
        },
        [
          {
            "title": "bar"
          },
          {
            "title": "baz"
          }
        ]
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "undefined argument",
    "template": "{{ a | map: nosuchthing | join: '#' }}",
    "want": "#",
    "context": {
      "a": [
        {
          "title": "foo"
        },
        {
          "title": "bar"
        }
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  }
]