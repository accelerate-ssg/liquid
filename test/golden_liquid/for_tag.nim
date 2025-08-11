

suite "loop functionality":
  testCase(
    "access parentloop",
    "{% for i in (1..2)%}{% for j in (1..2) %}{{ i }} {{j}} {{ forloop.parentloop.index }} {{ forloop.index }} {% endfor %}{% endfor %}",
    output = "1 1 1 1 1 2 1 2 2 1 2 1 2 2 2 2 "
  )

  testCase(
    "assign inside loop",
    "{% for tag in product.tags %}{% assign x = tag %}{% endfor %}{{ x }}",
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "garden"
  )

  testCase(
    "blank empty loops",
    "{% for i in (0..10) %}  {% endfor %}",
    output = ""
  )

  testCase(
    "break",
    "{% for tag in product.tags %}{% if tag == 'sports' %}{% break %}{% else %}{{ tag }} {% endif %}{% else %}no images{% endfor %}",
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = ""
  )

  testCase(
    "comma separated arguments",
    "{% for i in (1..6), limit: 4, offset: 2 %}{{ i }} {% endfor %}",
    output = "3 4 5 6 "
  )

  testCase(
    "continue",
    "{% for tag in product.tags %}{% if tag == 'sports' %}{% continue %}{% else %}{{ tag }} {% endif %}{% else %}no images{% endfor %}",
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "garden "
  )

  testCase(
    "continue a loop",
    "{% for item in array limit: 3 %}a{{ item }} {% endfor %}{% for item in array offset: continue %}b{{ item }} {% endfor %}",
    context = %*{"array": [1, 2, 3, 4, 5, 6]},
    output = "a1 a2 a3 b4 b5 b6 "
  )

  testCase(
    "continue a loop over a changing array",
    "{% assign foo = '1,2,3,4,5,6' | split: ',' %}{% for item in foo limit: 3 %}{{ item }} {% endfor %}{% assign foo = 'u,v,w,x,y,z' | split: ',' %}{% for item in foo offset: continue %}{{ item }} {% endfor %}",
    output = "1 2 3 x y z "
  )

  testCase(
    "continue a loop over an assigned range",
    "{% assign nums = (1..5) %}{% for item in nums limit: 3 %}a{{ item }} {% endfor %}{% for item in nums offset: continue %}b{{ item }} {% endfor %}",
    output = "a1 a2 a3 b4 b5 "
  )

  testCase(
    "continue from a limit that is greater than length",
    "{% for item in array limit: 99 %}a{{ item }} {% endfor %}{% for item in array offset: continue %}b{{ item }} {% endfor %}",
    context = %*{"array": [1, 2, 3, 4, 5, 6]},
    output = "a1 a2 a3 a4 a5 a6 "
  )

  testCase(
    "continue from a range expression",
    "{% for item in (1..6) limit: 3 %}a{{ item }} {% endfor %}{% for item in (1..6) offset: continue %}b{{ item }} {% endfor %}",
    context = %*{"array": [1, 2, 3, 4, 5, 6]},
    output = "a1 a2 a3 b4 b5 b6 "
  )

  testCase(
    "continue with changing loop var",
    "{% for foo in array limit: 3 %}{{ foo }} {% endfor %}{% for bar in array offset: continue %}{{ bar }} {% endfor %}",
    context = %*{"array": [1, 2, 3, 4, 5, 6]},
    output = "1 2 3 4 5 6 "
  )

  testCase(
    "empty array with default",
    "{% for img in emptythings.array %}{{ img.url }} {% else %}no images{% endfor %}",
    context = %*{"emptythings": {"array": [], "map": {}, "string": ""}},
    output = "no images"
  )

  testCase(
    "first and last with an offset and limit",
    "{% for tag in tags limit: 2 offset: 1 %}{{ tag }} {{ forloop.first }} {{ forloop.last }} {% endfor %}",
    context = %*{"tags": ["sports", "garden", "home", "diy", "motoring", "fashion"]},
    output = "garden true false home false true "
  )

  testCase(
    "first and last with offset continue",
    "{% for tag in product.tags limit: 1 %}{% endfor %}{% for tag in product.tags offset: continue %}{{ forloop.first }} {{ forloop.last }} {% endfor %}",
    context = %*{"product": {"tags": ["sports", "garden", "home", "diy", "motoring", "fashion"]}},
    output = "true false false false false false false false false true "
  )

  testCase(
    "forloop goes out of scope",
    "{% for tag in product.tags %}{{ forloop.length }} {% endfor %}{{ forloop.length }}",
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "2 2 "
  )

  testCase(
    "forloop length",
    "{% for tag in product.tags %}{{ forloop.length }} {% endfor %}",
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "2 2 "
  )

  testCase(
    "forloop length with limit",
    "{% for tag in tags limit:3 %}{{ forloop.length }} {% endfor %}",
    context = %*{"tags": ["sports", "garden", "home", "diy", "motoring", "fashion"]},
    output = "3 3 3 "
  )

  testCase(
    "forloop length with offset",
    "{% for tag in tags offset:3 %}{{ forloop.length }} {% endfor %}",
    context = %*{"tags": ["sports", "garden", "home", "diy", "motoring", "fashion"]},
    output = "3 3 3 "
  )

  testCase(
    "forloop name",
    "{% for tag in product.tags limit:1 %}{{ forloop.name }}{% endfor %}",
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "tag-product.tags"
  )
  
  testCase(
    "forloop name of a range",
    "{% for i in (1..3) limit:1 %}{{ forloop.name }}{% endfor %}",
    output = "i-(1..3)"
  )

  testCase(
    "forloop no such attribute",
    "{% for tag in product.tags %}{{ forloop.nosuchthing }}{% endfor %}",
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = ""
  )

  testCase(
    "forloop.first",
    "{% for tag in product.tags %}{{ forloop.first }} {% endfor %}",
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "true false "
  )

  testCase(
    "forloop.index",
    "{% for tag in product.tags %}{{ forloop.index }} {% endfor %}",
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "1 2 "
  )

  testCase(
    "forloop.index0",
    "{% for tag in product.tags %}{{ forloop.index0 }} {% endfor %}",
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "0 1 "
  )
  
  testCase(
    "forloop.last",
    "{% for tag in product.tags %}{{ forloop.last }} {% endfor %}",
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "false true "
  )

  testCase(
    "forloop.rindex",
    "{% for tag in product.tags %}{{ forloop.rindex }} {% endfor %}",
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "2 1 "
  )

  testCase(
    "forloop.rindex0",
    "{% for tag in product.tags %}{{ forloop.rindex0 }} {% endfor %}",
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "1 0 "
  )

  testCase(
    "iterate an empty array",
    "{% for item in emptythings.array %}{{ item }}{% endfor %}",
    context = %*{"emptythings": {"array": [], "map": {}, "string": ""}},
    output = ""
  )

  testCase(
    "iterate an empty array with default",
    "{% for item in emptythings.array %}{{ item }}{% else %}foo{% endfor %}",
    context = %*{"emptythings": {"array": [], "map": {}, "string": ""}},
    output = "foo"
  )
  
  testCase(
    "limit",
    "{% for tag in product.tags limit:1 %}{{ tag }} {% endfor %}",
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "sports "
  )

  testCase(
    "limit is a non-number string",
    "{% for i in (1..4) limit: 'foo' %}{{ i }} {% endfor %}",
    error = true
  )

  testCase(
    "limit is a string",
    "{% for i in (1..4) limit: '2' %}{{ i }} {% endfor %}",
    output = "1 2 "
  )

  testCase(
    "limit is not a string or number",
    "{% for i in (1..4) limit: foo %}{{ i }} {% endfor %}",
    context = %*{"foo": [1, 2, 3]},
    error = true
  )

  testCase(
    "lookup a filter from an outer context",
    "{% for tag in product.tags %}{{ tag | upcase }} {% endfor %}",
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "SPORTS GARDEN "
  )

  testCase(
    "loop over a string literal",
    "{% for i in 'hello' %}{{ i }} {% endfor %}",
    output = "hello "
  )

  testCase(
    "loop over a string variable",
    "{% for i in foo %}{{ i }} {% endfor %}",
    context = %*{"foo": "hello"},
    output = "hello "
  )

  testCase(
    "loop over an array in reverse",
    "{% for tag in product.tags reversed %}{{ tag }} {% endfor %}",
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "garden sports "
  )

  testCase(
    "loop over an existing range object",
    "{% assign foo = (1..3) %}{{ foo | join: '#' }}{% for i in foo %}{{ i }}{% endfor %}{% for i in foo %}{{ i }}{% endfor %}",
    output = "1#2#3123123"
  )

  testCase(
    "loop over nested and chained object from context with trailing identifier",
    "{% for link in linklists[section.settings.menu].links %}{{ link }} {% endfor %}",
    context = %*{
      "linklists": {
        "main": {
          "links": ["1", "2"]
        }
      },
      "section": {
        "settings": {
          "menu": "main"
        }
      }
    },
    output = "1 2 "
  )

  testCase(
    "loop over range with float start",
    "{% assign x = (2.4..5) %}{% for i in x %}{{ i }}{% endfor %}",
    output = "2345"
  )

  testCase(
    "loop over undefined",
    "{% for tag in nosuchthing %}{{ tag }}{% endfor %}",
    output = ""
  )

  testCase(
    "nothing to continue from",
    "{% for item in array %}a{{ item }} {% endfor %}{% for item in array offset: continue %}b{{ item }} {% endfor %}",
    context = %*{"array": [1, 2, 3, 4, 5, 6]},
    output = "a1 a2 a3 a4 a5 a6 "
  )

  testCase(
    "offset",
    "{% for tag in product.tags offset:1 %}{{ tag }} {% endfor %}",
    context = %*{"product": {"tags": ["sports", "garden"]}},
    output = "garden "
  )

  testCase(
    "offset and limit",
    "{% for tag in tags limit: 3 offset: 1 %}{{ tag }} {% endfor %}",
    context = %*{"tags": ["sports", "garden", "home", "diy", "motoring", "fashion"]},
    output = "garden home diy "
  )

  testCase(
    "offset continue forloop length",
    "{% for item in (1..6) limit: 2 %}a{{ item }} - {{ forloop.length }}, {% endfor %}{% for item in (1..6) offset: continue %}b{{ item }} - {{ forloop.length }}, {% endfor %}",
    output = "a1 - 2, a2 - 2, b3 - 4, b4 - 4, b5 - 4, b6 - 4, "
  )

  testCase(
    "offset continue from a broken loop",
    "{% for item in (1..6) limit: 4 %}{% if item == 3 %}{% break %}{% endif %}a{{ item }} {% endfor %}{% for item in (1..6) offset: continue %}b{{ item }} {% endfor %}",
    output = "a1 a2 b5 b6 "
  )

  testCase(
    "offset continue from a broken loop with preceding limit",
    "{% for item in (1..6) limit: 3 %}a{{ item }} {% endfor %}{% for item in (1..6) %}{% if item == 3 %}{% break %}{% endif %}b{{ item }} {% endfor %}{% for item in (1..6) offset: continue %}c{{ item }} {% endfor %}",
    output = "a1 a2 a3 b1 b2 "
  )

  testCase(
    "offset continue twice with changing limit",
    "{% for item in (1..6) limit: 2 %}a{{ item }} {% endfor %}{% for item in (1..6) limit: 3 offset: continue %}b{{ item }} {% endfor %}{% for item in (1..6) offset: continue %}c{{ item }} {% endfor %}",
    output = "a1 a2 b3 b4 b5 c6 "
  )

  testCase(
    "offset is a non-number string",
    "{% for i in (1..4) offset: 'foo' %}{{ i }} {% endfor %}",
    error = true
  )

  testCase(
    "offset is a string",
    "{% for i in (1..4) offset: '2' %}{{ i }} {% endfor %}",
    output = "3 4 "
  )

  testCase(
    "offset is not a string or number",
    "{% for i in (1..4) offset: foo %}{{ i }} {% endfor %}",
    context = %*{"foo": [1, 2, 3]},
    error = true
  )

  testCase(
    "parent's parentloop",
    "{% for i in (1..2) %}{% for j in (1..2) %}{% for k in (1..2) %}i={{ forloop.parentloop.parentloop.index }} j={{ forloop.parentloop.index }} k={{ forloop.index }} {% endfor %}{% endfor %}{% endfor %}",
    output = "i=1 j=1 k=1 i=1 j=1 k=2 i=1 j=2 k=1 i=1 j=2 k=2 i=2 j=1 k=1 i=2 j=1 k=2 i=2 j=2 k=1 i=2 j=2 k=2 "
  )

  testCase(
    "parentloop goes out of scope",
    "{% for i in (1..2)%}{% for j in (1..2) %}{{ i }} {{ j }} {% endfor %}{{ forloop.parentloop.index }}{% endfor %}",
    output = "1 1 1 2 2 1 2 2 "
  )

  testCase(
    "parentloop is normally undefined",
    "{% for i in (1..2)%}{{ forloop.parentloop.index }}{% endfor %}",
    output = ""
  )

  testCase(
    "range loop using identifier",
    "{% for i in (0..product.end_range) %}{{ i }} - {{ product.tags[i] }} {% endfor %}",
    context = %*{
      "product": {
        "tags": ["sports", "garden"],
        "end_range": 1
      }
    },
    output = "0 - sports 1 - garden "
  )

  testCase(
    "range start and stop are the same",
    "{% for i in (1..1) %}{{ i }} {% endfor %}",
    output = "1 "
  )

  testCase(
    "range start and stop are zero",
    "{% for i in (0..0) %}{{ i }} {% endfor %}",
    output = "0 "
  )

  testCase(
    "share outer scope",
    "{% assign foo = 'hello' %}{% for x in (1..3) %}{% assign foo = x %}{% endfor %}{{ foo }}",
    output = "3"
  )
  
  testCase(
    "simple array loop",
    "{% for tag in product.tags %}{{ tag }} {% endfor %}",
    context = %*{
      "product": {
        "tags": ["sports", "garden"]
      }
    },
    output = "sports garden "
  )

  testCase(
    "simple hash loop",
    "{% for c in collection %}{{ c[0] }} {{ c[1] }} {% endfor %}",
    context = %*{
      "collection": {
        "title": "foo",
        "description": "bar"
      }
    },
    output = "title foo description bar "
  )

  testCase(
    "simple range loop",
    "{% for i in (0..3) %}{{ i }} {% endfor %}",
    output = "0 1 2 3 "
  )

  testCase(
    "some comma separated arguments",
    "{% for i in (1..6) limit: 4, offset: 2, %}{{ i }} {% endfor %}",
    output = "3 4 5 6 "
  )
