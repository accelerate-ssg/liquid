[
  {
    "name": "array of hashes",
    "template": "{% assign x = a | where: 'title' %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}",
    "want": "(title,foo)(title,bar)",
    "context": {
      "a": [
        {
          "title": "foo"
        },
        {
          "title": "bar"
        },
        {
          "title": null
        }
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "array of hashes with a missing key",
    "template": "{% assign x = a | where: 'title', 'bar' %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}",
    "want": "(title,bar)",
    "context": {
      "a": [
        {
          "heading": "foo"
        },
        {
          "title": "bar"
        },
        {
          "title": null
        }
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "array of hashes with equality test",
    "template": "{% assign x = a | where: 'title', 'bar' %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}",
    "want": "(title,bar)",
    "context": {
      "a": [
        {
          "title": "foo"
        },
        {
          "title": "bar"
        },
        {
          "title": null
        }
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "both arguments are undefined",
    "template": "{{ a | where: nosuchthing, nothing }}",
    "want": "",
    "context": {
      "a": [
        {
          "title": "foo"
        },
        {
          "title": "bar"
        },
        {
          "title": null
        }
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "first argument is undefined",
    "template": "{{ a | where: nosuchthing }}",
    "want": "",
    "context": {
      "a": [
        {
          "title": "foo"
        },
        {
          "title": "bar"
        },
        {
          "title": null
        }
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "left value is not an array",
    "template": "{{ a | where: 'title' }}",
    "want": "",
    "context": {
      "a": 123
    },
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "left value is undefined",
    "template": "{{ nosuchthing | where: 'title' }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "missing argument",
    "template": "{{ a | where }}",
    "want": "",
    "context": {
      "a": [
        {
          "title": "foo"
        },
        {
          "title": "bar"
        },
        {
          "title": null
        }
      ]
    },
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "second argument is undefined",
    "template": "{% assign x = a | where: 'title', nosuchthing %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}",
    "want": "(title,foo)(title,bar)",
    "context": {
      "a": [
        {
          "title": "foo"
        },
        {
          "title": "bar"
        },
        {
          "title": null
        }
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "too many arguments",
    "template": "{{ a | where: 'title', 'foo', 'bar' }}",
    "want": "",
    "context": {
      "a": [
        {
          "title": "foo"
        },
        {
          "title": "bar"
        },
        {
          "title": null
        }
      ]
    },
    "partials": {},
    "error": true,
    "strict": false
  },
  {
    "name": "value is explicit nil",
    "template": "{% assign x =  a | where: 'b', nil %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}",
    "want": "(b,bar)",
    "context": {
      "a": [
        {
          "b": false
        },
        {
          "b": "bar"
        },
        {
          "b": null
        }
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "value is false",
    "template": "{% assign x =  a | where: 'b', false %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}",
    "want": "(b,false)",
    "context": {
      "a": [
        {
          "b": false
        },
        {
          "b": "bar"
        },
        {
          "b": null
        }
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  }
]