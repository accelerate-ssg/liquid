[
  {
    "name": "end is less than start",
    "template": "{{ (start..end) | join: '#' }}",
    "want": "",
    "context": {
      "start": 5,
      "end": 1
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "end is not a number",
    "template": "{{ (start..end) | join: '#' }}",
    "want": "",
    "context": {
      "start": "1",
      "end": "foo"
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "start and end are negative",
    "template": "{{ (start..end) | join: '#' }}",
    "want": "-5#-4#-3#-2",
    "context": {
      "start": -5,
      "end": -2
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "start is negative",
    "template": "{{ (start..end) | join: '#' }}",
    "want": "-5#-4#-3#-2#-1#0#1",
    "context": {
      "start": -5,
      "end": 1
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "start is not a number",
    "template": "{{ (start..end) | join: '#' }}",
    "want": "0#1#2#3#4#5",
    "context": {
      "start": "foo",
      "end": 5
    },
    "partials": {},
    "error": false,
    "strict": false
  }
]