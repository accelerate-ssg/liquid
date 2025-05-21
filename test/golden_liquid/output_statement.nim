[
  {
    "name": "access an array item by index",
    "template": "{{ product.tags[1] }}",
    "want": "garden",
    "context": {
      "product": {
        "tags": [
          "sports",
          "garden"
        ]
      }
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "access an array item by negative index",
    "template": "{{ product.tags[-2] }}",
    "want": "sports",
    "context": {
      "product": {
        "tags": [
          "sports",
          "garden"
        ]
      }
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "access an undefined variable by index",
    "template": "{{ nosuchthing[0] }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "access array item by index stored in a local variable",
    "template": "{% assign i = 1 %}{{ product.tags[i] }}",
    "want": "garden",
    "context": {
      "product": {
        "tags": [
          "sports",
          "garden"
        ]
      }
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "assign a variable the value of an existing variable",
    "template": "{% capture some %}hello{% endcapture %}{% assign other = some %}{% assign some = 'foo' %}{{ some }}-{{ other }}",
    "want": "foo-hello",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "bracketed variable resolves to a string",
    "template": "{{ foo[something] }}",
    "want": "goodbye",
    "context": {
      "foo": {
        "hello": "goodbye"
      },
      "something": "hello"
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "bracketed variable resolves to a string without leading identifier",
    "template": "{{ [something] }}",
    "want": "goodbye",
    "context": {
      "something": "hello",
      "hello": "goodbye"
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "chained bracketed identifier index",
    "template": "{{ products[0].title }}",
    "want": "shoe",
    "context": {
      "products": [
        {
          "title": "shoe"
        },
        {
          "title": "hat"
        }
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "chained bracketed identifier index no dot",
    "template": "{{ products[0]title }}",
    "want": "shoe",
    "context": {
      "products": [
        {
          "title": "shoe"
        },
        {
          "title": "hat"
        }
      ]
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "chained identifier dot separated index",
    "template": "{{ products.0.title }}",
    "want": "",
    "context": {
      "products": [
        {
          "title": "shoe"
        },
        {
          "title": "hat"
        }
      ]
    },
    "partials": {},
    "error": true,
    "strict": true
  },
  {
    "name": "dump an array from the global context",
    "template": "{{ product.tags | join: '#' }}",
    "want": "sports#garden",
    "context": {
      "product": {
        "tags": [
          "sports",
          "garden"
        ]
      }
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "nested bracketed variable resolving to a string",
    "template": "{{ [list[settings.zero]] }}",
    "want": "bar",
    "context": {
      "list": [
        "foo"
      ],
      "settings": {
        "zero": 0
      },
      "foo": "bar"
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "quoted, bracketed variable name",
    "template": "{{ foo['bar'] }}",
    "want": "42",
    "context": {
      "foo": {
        "bar": 42
      }
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "quoted, bracketed variable name with whitespace",
    "template": "{{ foo['bar baz'] }}",
    "want": "42",
    "context": {
      "foo": {
        "bar baz": 42
      }
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "render a default given a literal false",
    "template": "{{ false | default: 'bar' }}",
    "want": "bar",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "render a default given a literal false with 'allow false' equal to false",
    "template": "{{ false | default: 'bar', allow_false: false }}",
    "want": "bar",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "render a default given a literal false with 'allow false' equal to true",
    "template": "{{ false | default: 'bar', allow_false: true }}",
    "want": "false",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "render a float literal",
    "template": "{{ 1.23 }}",
    "want": "1.23",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "render a global variable with a filter",
    "template": "{{ product.title | upcase }}",
    "want": "FOO",
    "context": {
      "product": {
        "title": "foo"
      }
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "render a negative integer literal",
    "template": "{{ -123 }}",
    "want": "-123",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "render a range object",
    "template": "{{ (1..5) | join: '#' }}",
    "want": "1#2#3#4#5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "render a range object that uses a float",
    "template": "{{ (1.4..5) | join: '#' }}",
    "want": "1#2#3#4#5",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "render a range object that uses an identifier",
    "template": "{{ (foo..5) | join: '#' }}",
    "want": "2#3#4#5",
    "context": {
      "foo": 2
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "render a string literal",
    "template": "{{ 'hello' }}",
    "want": "hello",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "render a variable from the global namespace",
    "template": "{{ product.title }}",
    "want": "foo",
    "context": {
      "product": {
        "title": "foo"
      }
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "render a variable from the local namespace",
    "template": "{% assign name = 'Brian' %}{{ name }}",
    "want": "Brian",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "render an integer literal",
    "template": "{{ 123 }}",
    "want": "123",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "render an output start sequence as a string literal",
    "template": "{{ '{{' }}",
    "want": "{{",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "render an undefined property",
    "template": "{{ product.age }}",
    "want": "",
    "context": {
      "product": {
        "title": "foo"
      }
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "render an undefined variable",
    "template": "{{ age }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "render nil",
    "template": "{{ nil }}",
    "want": "",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "reverse a range",
    "template": "{{ (foo..5) | reverse | join: '#' }}",
    "want": "5#4#3#2",
    "context": {
      "foo": 2
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "top-level quoted, bracketed variable name with whitespace",
    "template": "{{ ['bar baz'] }}",
    "want": "42",
    "context": {
      "bar baz": 42
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "top-level quoted, bracketed variable name with whitespace followed by dot notation",
    "template": "{{ ['bar baz'].qux }}",
    "want": "42",
    "context": {
      "bar baz": {
        "qux": 42
      }
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "traverse variables with bracketed identifiers",
    "template": "{{ site.data.menu[include.menu][include.locale] }}",
    "want": "it works!",
    "context": {
      "site": {
        "data": {
          "menu": {
            "foo": {
              "bar": "it works!"
            }
          }
        }
      },
      "include": {
        "menu": "foo",
        "locale": "bar"
      }
    },
    "partials": {},
    "error": false,
    "strict": false
  },
  {
    "name": "unexpected left value for the `join` filter passes through",
    "template": "{{ 12 | join: '#' }}",
    "want": "12",
    "context": {},
    "partials": {},
    "error": false,
    "strict": false
  }
]