[
  {
    "name": "empty sequence",
    "template": "{{ a | sum }}",
    "want": "0",
    "context": {
      "a": []
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "hashes with numeric strings and property argument",
    "template": "{{ a | sum: 'k' }}",
    "want": "6",
    "context": {
      "a": [
        {
          "k": "1"
        },
        {
          "k": "2"
        },
        {
          "k": "3"
        }
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "hashes with property argument",
    "template": "{{ a | sum: 'k' }}",
    "want": "6",
    "context": {
      "a": [
        {
          "k": 1
        },
        {
          "k": 2
        },
        {
          "k": 3
        }
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "hashes with some missing properties",
    "template": "{{ a | sum: 'k' }}",
    "want": "3",
    "context": {
      "a": [
        {
          "k": 1
        },
        {
          "k": 2
        },
        {
          "x": 3
        }
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "hashes without property argument",
    "template": "{{ a | sum }}",
    "want": "0",
    "context": {
      "a": [
        {
          "k": 1
        },
        {
          "k": 2
        },
        {
          "k": 3
        }
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "ints",
    "template": "{{ a | sum }}",
    "want": "6",
    "context": {
      "a": [
        1,
        2,
        3
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "negative ints",
    "template": "{{ a | sum }}",
    "want": "-6",
    "context": {
      "a": [
        -1,
        -2,
        -3
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "negative strings",
    "template": "{{ a | sum }}",
    "want": "-6",
    "context": {
      "a": [
        "-1",
        "-2",
        "-3"
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "nested ints",
    "template": "{{ a | sum }}",
    "want": "6",
    "context": {
      "a": [
        1,
        [
          2,
          [
            3
          ]
        ]
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "only zeros",
    "template": "{{ a | sum }}",
    "want": "0",
    "context": {
      "a": [
        0,
        0,
        0
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "positive and negative ints",
    "template": "{{ a | sum }}",
    "want": "5",
    "context": {
      "a": [
        -2,
        -3,
        10
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "properties arguments with non-hash items",
    "template": "{{ a | sum: 'k' }}",
    "want": "3",
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