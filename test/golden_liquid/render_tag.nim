[
  {
    "name": "assign to keyword argument",
    "template": "{% render 'product-args', foo: 'hello' %}{{ foo }}",
    "want": "hello goodbye",
    "context": {},
    "partials": {
      "product-args": "{{ foo }}{% assign foo='goodbye' %} {{ foo }}"
    },
    "error": false,
    "strict": false
  },
  {
    "name": "assigned variables do not leak into outer scope",
    "template": "{% render 'assign-outer-scope', customer: customer %} {{ last_name }}",
    "want": "Hello, Holly ",
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
    "name": "bound array variable",
    "template": "{% render 'prod' for collection.products %}",
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
    "template": "{% render 'product-title' with collection.products[1] %}",
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
    "template": "{% render 'product-title' with no.such.thing %}",
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
    "template": "{% render 'product-alias' with collection.products[1] as product %}",
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
    "name": "decrement is isolated between renders",
    "template": "{% decrement foo %} {% render 'decrement' %} {% decrement foo %}",
    "want": "-1 -1 -2",
    "context": {},
    "partials": {
      "decrement": "{% decrement foo %}"
    },
    "error": false,
    "strict": false
  },
  {
    "name": "for loop variables go out of scope",
    "template": "{% for i in (1..3) %}{{ i }}{% render 'loop-scope' %}{{ i }}{% endfor %}{{ i }}",
    "want": "112233",
    "context": {},
    "partials": {
      "loop-scope": "{{ i }}"
    },
    "error": false,
    "strict": false
  },
  {
    "name": "forloop helper",
    "template": "{% render 'product' for collection.products %}",
    "want": "Product: bike first index:1 Product: car last index:2 ",
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
      "product": "Product: {{ product.title }} {% if forloop.first %}first{% endif %}{% if forloop.last %}last{% endif %} index:{{ forloop.index }} "
    },
    "error": false,
    "strict": false
  },
  {
    "name": "increment is isolated between renders",
    "template": "{% increment foo %} {% render 'increment' %} {% increment foo %}",
    "want": "0 0 1",
    "context": {},
    "partials": {
      "increment": "{% increment foo %}"
    },
    "error": false,
    "strict": false
  },
  {
    "name": "parent variables go out of scope",
    "template": "{% assign greeting = 'good morning' %}{{ greeting }} {% render 'outer-scope' %}{{ greeting }}",
    "want": "good morning good morning",
    "context": {},
    "partials": {
      "outer-scope": "{{ greeting }}"
    },
    "error": false,
    "strict": false
  },
  {
    "name": "render loops can't access parentloop",
    "template": "{% for x in (1..3) %}{% render 'product' for collection.products %}{% endfor %}",
    "want": "bike-0 car-1 bike-0 car-1 bike-0 car-1 ",
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
      "product": "{{ product.title }}-{{ forloop.index0 }} {{ forloop.parentloop.index0 }}"
    },
    "error": false,
    "strict": false
  },
  {
    "name": "render loops don't add parentloop",
    "template": "{% render 'product' for collection.products %}",
    "want": "bike-0 0 1 2 car-1 0 1 2 ",
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
      "product": "{{ product.title }}-{{ forloop.index0 }} {% for x in (1..3) %}{{ forloop.index0 }}{{ forloop.parentloop.index0 }} {% endfor %}"
    },
    "error": false,
    "strict": false
  },
  {
    "name": "some keyword arguments",
    "template": "{% render 'product-args', foo: 'hello', bar: 'there' %}",
    "want": "hello there",
    "context": {},
    "partials": {
      "product-args": "{{ foo }} {{ bar }}"
    },
    "error": false,
    "strict": false
  },
  {
    "name": "some keyword arguments including a range literal",
    "template": "{% render 'product-args', foo: (1..3), bar: 'there' %}",
    "want": "1#2#3 there",
    "context": {},
    "partials": {
      "product-args": "{{ foo | join: '#' }} {{ bar }}"
    },
    "error": false,
    "strict": false
  },
  {
    "name": "some keyword arguments no leading coma",
    "template": "{% render 'product-args' foo: 'hello', bar: 'there' %}",
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
    "template": "{% render 'product-hero', product: product %}",
    "want": "foo\n- sports - garden ",
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
      "product-hero": "{{ product.title }}\n{% for tag in product.tags %}- {{ tag }} {% endfor %}"
    },
    "error": false,
    "strict": false
  }
]