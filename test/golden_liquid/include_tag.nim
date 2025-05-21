[
  {
    "name": "assign persists in outer scope",
    "template": "{% include 'assign-outer-scope' %} {{ last_name }}",
    "want": "Hello, Holly Smith",
    "context": {
      "customer": {
        "first_name": "Holly"
      }
    },
    "partials": {
      "assign-outer-scope": "Hello, {{ customer.first_name }}{% assign last_name = 'Smith' %}"
    },
    "error": false,
    "strict": false
  },
  {
    "name": "assign to a keyword argument",
    "template": "{% include 'product-args', foo: 'hello' %} {{ foo }}",
    "want": "hello hello goodbye",
    "context": {},
    "partials": {
      "product-args": "{{ foo }}{% assign foo = 'goodbye' %} {{ foo }}"
    },
    "error": false,
    "strict": false
  },
  {
    "name": "bound array variable",
    "template": "{% include 'prod' for collection.products %}",
    "want": "bikecar",
    "context": {
      "collection": {
        "products": [
          {
            "title": "bike"
          },
          {
            "title": "car"
          }
        ]
      }
    },
    "partials": {
      "prod": "{{ prod.title }}"
    },
    "error": false,
    "strict": false
  },
  {
    "name": "bound variable",
    "template": "{% include 'product-title' with collection.products[1] %}",
    "want": "car",
    "context": {
      "collection": {
        "products": [
          {
            "title": "bike"
          },
          {
            "title": "car"
          }
        ]
      }
    },
    "partials": {
      "product-title": "{{ product-title.title }}"
    },
    "error": false,
    "strict": false
  },
  {
    "name": "bound variable does not exist",
    "template": "{% include 'product-title' with no.such.thing %}",
    "want": "",
    "context": {},
    "partials": {
      "product-title": "{{ product-title.title }}"
    },
    "error": false,
    "strict": false
  },
  {
    "name": "bound variable with alias",
    "template": "{% include 'product-alias' with collection.products[1] as product %}",
    "want": "car",
    "context": {
      "collection": {
        "products": [
          {
            "title": "bike"
          },
          {
            "title": "car"
          }
        ]
      }
    },
    "partials": {
      "product-alias": "{{ product.title }}"
    },
    "error": false,
    "strict": false
  },
  {
    "name": "break from include",
    "template": "{% for tag in product.tags %}{% include 'tag-break' %}{% endfor %}",
    "want": "SPORTS",
    "context": {
      "product": {
        "tags": [
          "sports",
          "garden"
        ]
      }
    },
    "partials": {
      "tag-break": "{{ tag | upcase }}{% break %}"
    },
    "error": false,
    "strict": false
  },
  {
    "name": "break from nested include",
    "template": "{% for tag in product.tags %}{% include 'tag' %}{% endfor %}",
    "want": "SPORTS break!",
    "context": {
      "product": {
        "tags": [
          "sports",
          "garden"
        ]
      }
    },
    "partials": {
      "tag": "{{ tag | upcase }}{% include 'break' %}",
      "break": " break!{% break %}"
    },
    "error": false,
    "strict": false
  },
  {
    "name": "counter from outer scope",
    "template": "{% increment foo %} {% include 'increment-outer-scope' %} {% increment foo %}",
    "want": "0 1 2",
    "context": {},
    "partials": {
      "increment-outer-scope": "{% increment foo %}"
    },
    "error": false,
    "strict": false
  },
  {
    "name": "keyword arguments go out of scope",
    "template": "{% include 'product-args', foo: 'hello', bar: 'there' %}{{ foo }}",
    "want": "hello there",
    "context": {},
    "partials": {
      "product-args": "{{ foo }} {{ bar }}"
    },
    "error": false,
    "strict": false
  },
  {
    "name": "name from identifier",
    "template": "{% include snippet %}",
    "want": "foo\n- sports\n- garden\n",
    "context": {
      "snippet": "product-hero",
      "product": {
        "title": "foo",
        "tags": [
          "sports",
          "garden"
        ]
      }
    },
    "partials": {
      "product-hero": "{{ product.title }}\n{% for tag in product.tags %}- {{ tag }}\n{% endfor %}"
    },
    "error": false,
    "strict": false
  },
  {
    "name": "some keyword arguments",
    "template": "{% include 'product-args', foo: 'hello', bar: 'there' %}",
    "want": "hello there",
    "context": {},
    "partials": {
      "product-args": "{{ foo }} {{ bar }}"
    },
    "error": false,
    "strict": false
  },
  {
    "name": "some keyword arguments with float literals",
    "template": "{% include 'product-args' foo: 1.1, bar: 'there' %}",
    "want": "1.1 there",
    "context": {},
    "partials": {
      "product-args": "{{ foo }} {{ bar }}"
    },
    "error": false,
    "strict": false
  },
  {
    "name": "some keyword arguments with range literal",
    "template": "{% include 'product-args' foo: (1..3), bar: 'there' %}",
    "want": "1#2#3 there",
    "context": {},
    "partials": {
      "product-args": "{{ foo | join: '#' }} {{ bar }}"
    },
    "error": false,
    "strict": false
  },
  {
    "name": "some keyword arguments without leading comma",
    "template": "{% include 'product-args' foo: 'hello', bar: 'there' %}",
    "want": "hello there",
    "context": {},
    "partials": {
      "product-args": "{{ foo }} {{ bar }}"
    },
    "error": false,
    "strict": false
  },
  {
    "name": "string literal name",
    "template": "{% include 'product-hero' %}",
    "want": "foo\n- sports\n- garden\n",
    "context": {
      "product": {
        "title": "foo",
        "tags": [
          "sports",
          "garden"
        ]
      }
    },
    "partials": {
      "product-hero": "{{ product.title }}\n{% for tag in product.tags %}- {{ tag }}\n{% endfor %}"
    },
    "error": false,
    "strict": false
  },
  {
    "name": "use globals from outer scope",
    "template": "{% include 'outer-scope' %}",
    "want": "Hello, Holly",
    "context": {
      "customer": {
        "first_name": "Holly"
      }
    },
    "partials": {
      "outer-scope": "Hello, {{ customer.first_name }}"
    },
    "error": false,
    "strict": false
  }
]