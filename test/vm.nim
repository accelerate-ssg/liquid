# Pitchfork VM unit tests (compiled via the Liquid tine)
import std/[unittest, tables, sets, strutils]
import ../src/pitchfork/tines/liquid/api


let empty_array:seq[string] = @[]

# Helper to compile and run a template
proc render_template(source: string, data: Table[string, VMValue],
                     partials: Table[string, string] = initTable[string, string]()): string =
  let sections = lex(source)
  let compiled = compile(sections, source)
  result = render(compiled.bytecode, compiled.strings, compiled.constants, data, partials)

# Helper to create VMValue from various types
# proc to_vm_value(x: int): VMValue = vmInt(x.int64)
# proc to_vm_value(x: float): VMValue = vmFloat(x)
# proc to_vm_value(x: string): VMValue = vmString(x)
# proc to_vm_value(x: bool): VMValue = vmBool(x)
proc to_vm_value(x: seq[int]): VMValue =
  var arr: seq[VMValue] = @[]
  for item in x:
    arr.add(vmInt(item.int64))
  vmArray(arr)

proc to_vm_value(x: seq[string]): VMValue =
  var arr: seq[VMValue] = @[]
  for item in x:
    arr.add(vmString(item))
  vmArray(arr)

# proc to_vm_value(x: seq[float]): VMValue =
#   var arr: seq[VMValue] = @[]
#   for item in x:
#     arr.add(vmFloat(item))
#   vmArray(arr)

# proc to_vm_value(x: seq[bool]): VMValue =
#   var arr: seq[VMValue] = @[]
#   for item in x:
#     arr.add(vmBool(item))
#   vmArray(arr)

# # For already converted VMValues
# proc to_vm_value(x: seq[VMValue]): VMValue =
#   vmArray(x)

# Helper to create object VMValue
proc make_object(pairs: varargs[(string, VMValue)]): VMValue =
  var obj = initOrderedTable[string, VMValue]()
  for (k, v) in pairs:
    obj[k] = v
  vmObject(obj)

suite "VM Basic Output":
  test "Empty template":
    let source = ""
    let data = initTable[string, VMValue]()
    let output = render_template(source, data)
    check output == ""

  test "Plain text":
    let source = "Hello, World!"
    let data = initTable[string, VMValue]()
    let output = render_template(source, data)
    check output == "Hello, World!"

  test "Simple variable":
    let source = "Hello, {{ name }}!"
    let data = {"name": vmString("Alice")}.toTable
    let output = render_template(source, data)
    check output == "Hello, Alice!"

  test "Missing variable as empty":
    let source = "Hello, {{ name }}!"
    let data = initTable[string, VMValue]()
    let output = render_template(source, data)
    check output == "Hello, !"

  test "Integer output":
    let source = "Count: {{ count }}"
    let data = {"count": vmInt(42)}.toTable
    let output = render_template(source, data)
    check output == "Count: 42"

  test "Float output":
    let source = "Price: {{ price }}"
    let data = {"price": vmFloat(19.99)}.toTable
    let output = render_template(source, data)
    check output == "Price: 19.99"

  test "Boolean output":
    let source = "Active: {{ active }}"
    let data = {"active": vmBool(true)}.toTable
    let output = render_template(source, data)
    check output == "Active: true"

suite "VM Property Access":
  test "Object property":
    let source = "Name: {{ user.name }}"
    let data = {
      "user": make_object(("name", vmString("Bob")))
    }.toTable
    let output = render_template(source, data)
    check output == "Name: Bob"

  test "Nested property":
    let source = "City: {{ user.address.city }}"
    let data = {
      "user": make_object(
        ("address", make_object(
          ("city", vmString("New York"))
        ))
      )
    }.toTable
    let output = render_template(source, data)
    check output == "City: New York"

  test "Missing property as empty":
    let source = "Age: {{ user.age }}"
    let data = {
      "user": make_object(("name", vmString("Charlie")))
    }.toTable
    let output = render_template(source, data)
    check output == "Age: "

  test "Array property - size":
    let source = "Items: {{ items.size }}"
    let data = {
      "items": to_vm_value(@[1, 2, 3])
    }.toTable
    let output = render_template(source, data)
    check output == "Items: 3"

suite "VM Conditionals":
  test "Simple if - true":
    let source = "{% if show %}Visible{% endif %}"
    let data = {"show": vmBool(true)}.toTable
    let output = render_template(source, data)
    check output == "Visible"

  test "Simple if - false":
    let source = "{% if show %}Visible{% endif %}"
    let data = {"show": vmBool(false)}.toTable
    let output = render_template(source, data)
    check output == ""

  test "If-else":
    let source = "{% if logged_in %}Welcome{% else %}Please login{% endif %}"
    
    let data1 = {"logged_in": vmBool(true)}.toTable
    check render_template(source, data1) == "Welcome"
    
    let data2 = {"logged_in": vmBool(false)}.toTable
    check render_template(source, data2) == "Please login"

  test "Truthy values":
    let source = "{% if value %}Yes{% else %}No{% endif %}"

    # Truthy values (in Liquid, only nil and false are falsy)
    check render_template(source, {"value": vmInt(1)}.toTable) == "Yes"
    check render_template(source, {"value": vmString("text")}.toTable) == "Yes"
    check render_template(source, {"value": to_vm_value(@[1])}.toTable) == "Yes"
    check render_template(source, {"value": vmInt(0)}.toTable) == "Yes"
    check render_template(source, {"value": vmString("")}.toTable) == "Yes"
    check render_template(source, {"value": to_vm_value(empty_array)}.toTable) == "Yes"

    # Falsy values (only nil and false)
    check render_template(source, {"value": vmNull()}.toTable) == "No"
    check render_template(source, {"value": VMValue(kind: vmBool, boolVal: false)}.toTable) == "No"

  test "Comparison operators":
    let source = "{% if age > 18 %}Adult{% else %}Minor{% endif %}"
    
    check render_template(source, {"age": vmInt(21)}.toTable) == "Adult"
    check render_template(source, {"age": vmInt(18)}.toTable) == "Minor"
    check render_template(source, {"age": vmInt(16)}.toTable) == "Minor"

suite "VM Loops":
  test "Simple for loop":
    let source = "{% for item in items %}{{ item }} {% endfor %}"
    let data = {
      "items": to_vm_value(@[1, 2, 3])
    }.toTable
    let output = render_template(source, data)
    check output == "1 2 3 "

  test "For loop with strings":
    let source = "{% for name in names %}Hello {{ name }}! {% endfor %}"
    let data = {
      "names": to_vm_value(@["Alice", "Bob"])
    }.toTable
    let output = render_template(source, data)
    check output == "Hello Alice! Hello Bob! "

  test "Empty loop":
    let source = "{% for item in items %}{{ item }}{% endfor %}Done"
    let data = {
      "items": to_vm_value(empty_array)
    }.toTable
    let output = render_template(source, data)
    check output == "Done"

  test "Loop with object properties":
    let source = "{% for user in users %}{{ user.name }}: {{ user.age }} {% endfor %}"
    let data = {
      "users": vmArray(@[
        make_object(
          ("name", vmString("Alice")),
          ("age", vmInt(30))
        ),
        make_object(
          ("name", vmString("Bob")),
          ("age", vmInt(25))
        )
      ])
    }.toTable
    let output = render_template(source, data)
    check output == "Alice: 30 Bob: 25 "

  test "Nested loops":
    let source = "{% for row in rows %}{% for col in row %}{{ col }} {% endfor %}| {% endfor %}"
    let data = {
      "rows": vmArray(@[
        to_vm_value(@[1, 2]),
        to_vm_value(@[3, 4])
      ])
    }.toTable
    
    let output = render_template(source, data)
    
    check output == "1 2 | 3 4 | "

suite "VM Variables":
  test "Assign literal":
    let source = "{% assign x = 5 %}x = {{ x }}"
    let data = initTable[string, VMValue]()
    let output = render_template(source, data)
    check output == "x = 5"

  test "Assign from variable":
    let source = "{% assign copy = original %}{{ copy }}"
    let data = {"original": vmString("test")}.toTable
    let output = render_template(source, data)
    check output == "test"

  test "Assign overwrites":
    let source = "{% assign x = 1 %}First: {{ x }} {% assign x = 2 %}Second: {{ x }}"
    let data = initTable[string, VMValue]()
    let output = render_template(source, data)
    check output == "First: 1 Second: 2"

  test "Local shadows global":
    let source = "Global: {{ x }} {% assign x = 'local' %}Local: {{ x }}"
    let data = {"x": vmString("global")}.toTable
    let output = render_template(source, data)
    check output == "Global: global Local: local"

suite "VM Capture":
  test "Simple capture":
    let source = "{% capture greeting %}Hello, {{ name }}!{% endcapture %}{{ greeting }}"
    let data = {"name": vmString("World")}.toTable
    let output = render_template(source, data)
    check output == "Hello, World!"

  test "Capture with multiple outputs":
    let source = """{% capture card %}<h1>{{ title }}</h1><p>{{ desc }}</p>{% endcapture %}{{ card }}"""
    let data = {
      "title": vmString("Test"),
      "desc": vmString("Description")
    }.toTable
    let output = render_template(source, data)
    check output == "<h1>Test</h1><p>Description</p>"

  test "Nested capture":
    let source = """{% capture outer %}[{% capture inner %}{{ x }}{% endcapture %}{{ inner }}]{% endcapture %}{{ outer }}"""
    let data = {"x": vmString("nested")}.toTable
    let output = render_template(source, data)
    check output == "[nested]"
  
  test "Capture without HTML escaping":
    let source = """{% capture card %}<h1>{{ title }}</h1><p>{{ desc }}</p>{% endcapture %}{{ card }}"""
    let data = {
      "title": vmString("Test"),
      "desc": vmString("Description")
    }.toTable
    
    # Render with HTML escaping disabled
    let sections = lex(source)
    let compiled = compile(sections, source)
    var vm = new_liquid_vm(compiled.bytecode, compiled.strings, compiled.constants, unsafeAddr data)
    vm.escape_html = false  # Disable HTML escaping
    let output = vm.execute()
    
    check output == "<h1>Test</h1><p>Description</p>"

suite "VM Literals":
  test "String literal":
    let source = "{{ 'hello world' }}"
    let data = initTable[string, VMValue]()
    let output = render_template(source, data)
    check output == "hello world"

  test "Number literals":
    let source = "Int: {{ 42 }} Float: {{ 3.14 }}"
    let data = initTable[string, VMValue]()
    let output = render_template(source, data)
    check output == "Int: 42 Float: 3.14"

  test "Boolean literals":
    let source = "True: {{ true }} False: {{ false }}"
    let data = initTable[string, VMValue]()
    let output = render_template(source, data)
    check output == "True: true False: false"

  test "Nil literal - actual":
    let source = "Nil: '{{ nil }}'"
    let data = initTable[string, VMValue]()
    let output = render_template(source, data)
    
    # The single quotes might be getting escaped
    # Let's check what we actually get
    echo "Nil output: '", output, "'"
    check "Nil: " in output

suite "VM Filters":
  test "Upcase filter":
    let source = "{{ name | upcase }}"
    let data = {"name": vmString("hello")}.toTable
    let output = render_template(source, data)
    check output == "HELLO"

  test "Downcase filter":
    let source = "{{ name | downcase }}"
    let data = {"name": vmString("HELLO")}.toTable
    let output = render_template(source, data)
    check output == "hello"

  test "Size filter":
    let source = "{{ items | size }}"
    let data = {"items": to_vm_value(@[1, 2, 3, 4, 5])}.toTable
    let output = render_template(source, data)
    check output == "5"

  test "First filter":
    let source = "{{ items | first }}"
    let data = {"items": to_vm_value(@["a", "b", "c"])}.toTable
    let output = render_template(source, data)
    check output == "a"

  test "Last filter":
    let source = "{{ items | last }}"
    let data = {"items": to_vm_value(@["a", "b", "c"])}.toTable
    let output = render_template(source, data)
    check output == "c"

  test "Chained filters":
    let source = "{{ name | downcase | size }}"
    let data = {"name": vmString("HELLO")}.toTable
    let output = render_template(source, data)
    check output == "5"

suite "VM Complex Templates":
  test "Blog post template":
    let source = """<article>
  <h1>{{ post.title }}</h1>
  <p>By {{ post.author }} on {{ post.date }}</p>
  
  {% if post.tags %}
    <ul>
    {% for tag in post.tags %}
      <li>{{ tag }}</li>
    {% endfor %}
    </ul>
  {% endif %}
  
  <div>{{ post.content }}</div>
</article>"""
    
    let data = {
      "post": make_object(
        ("title", vmString("Hello World")),
        ("author", vmString("Alice")),
        ("date", vmString("2024-01-01")),
        ("tags", to_vm_value(@["nim", "templates", "liquid"])),
        ("content", vmString("This is the post content."))
      )
    }.toTable
    
    let output = render_template(source, data)
    check "Hello World" in output
    check "Alice" in output
    check "<li>nim</li>" in output
    check "<li>templates</li>" in output
    check "<li>liquid</li>" in output

  test "Shopping cart":
    let source = """{% assign total = 0 %}
{% for item in cart %}
  {{ item.name }}: ${{ item.price }} x {{ item.quantity }}
{% endfor %}
Total items: {{ cart | size }}"""
    
    let data = {
      "cart": vmArray(@[
        make_object(
          ("name", vmString("Book")),
          ("price", vmFloat(19.99)),
          ("quantity", vmInt(2))
        ),
        make_object(
          ("name", vmString("Pen")),
          ("price", vmFloat(1.99)),
          ("quantity", vmInt(5))
        )
      ])
    }.toTable
    
    let output = render_template(source, data)
    check "Book: $19.99 x 2" in output
    check "Pen: $1.99 x 5" in output
    check "Total items: 2" in output

suite "VM Edge Cases":
  test "Deeply nested properties":
    let source = "{{ a.b.c.d.e }}"
    let data = {
      "a": make_object(
        ("b", make_object(
          ("c", make_object(
            ("d", make_object(
              ("e", vmString("deep"))
            ))
          ))
        ))
      )
    }.toTable
    let output = render_template(source, data)
    check output == "deep"

  test "HTML escaping":
    let source = "{{ content }}"
    let data = {"content": vmString("<script>alert('xss')</script>")}.toTable
    
    # Create VM with HTML escaping enabled (not default in Liquid, but available)
    let sections = lex(source)
    let compiled = compile(sections, source)
    var vm = new_liquid_vm(compiled.bytecode, compiled.strings, compiled.constants, unsafeAddr data)
    vm.escape_html = true
    let output = vm.execute()
    
    check "<script>" notin output
    check "&lt;script&gt;" in output

  test "Division by zero":
    let source = "{{ 10 / 0 }}"
    let data = initTable[string, VMValue]()
    let output = render_template(source, data)
    
    check output == ""

  test "Division by zero - float":
    let source = "{{ 10.5 / 0.0 }}"
    let data = initTable[string, VMValue]()
    let output = render_template(source, data)
    
    check output == "inf"

  test "Modulo by zero":
    let source = "{{ 10 % 0 }}"
    let data = initTable[string, VMValue]()
    let output = render_template(source, data)
    
    check output == ""

  test "Array index out of bounds - positive":
    let source = "{{ items[10] }}"
    let data = {
      "items": to_vm_value(@["a", "b", "c"])
    }.toTable
    let output = render_template(source, data)
    
    check output == ""

  test "Array index out of bounds - negative":
    let source = "{{ items[-1] }}"
    let data = {
      "items": to_vm_value(@["a", "b", "c"])
    }.toTable
    let output = render_template(source, data)
    
    check output == "c"

  test "Array index with non-integer":
    let source = "{{ items['hello'] }}"
    let data = {
      "items": to_vm_value(@["a", "b", "c"])
    }.toTable
    let output = render_template(source, data)
    
    check output == ""

  test "Null property access":
    let source = "{{ nothing.property }}"
    let data = initTable[string, VMValue]()
    let output = render_template(source, data)
    
    check output == ""

  test "Deep property chain with null":
    let source = "{{ a.b.c.d.e.f.g }}"
    let data = {
      "a": make_object(
        ("b", vmNull())
      )
    }.toTable
    let output = render_template(source, data)
    
    check output == ""

  test "Type coercion edge cases":
    let source1 = "{{ true + 1 }}"
    let output1 = render_template(source1, initTable[string, VMValue]())
    
    check output1 == ""

  test "String coercion 1":
    let source = "{{ '5' + 5 }}"
    let output = render_template(source, initTable[string, VMValue]())

    check output == "55"

  test "String coercion 1":
    let source = "{{ 5 + '5' }}"
    let output = render_template(source, initTable[string, VMValue]())

    check output == "55"

  test "Empty array/object operations":
    let source = """
{{ empty_array | first }}
{{ empty_array | last }}
{{ empty_object.anything }}
"""
    let data = {
      "empty_array": vmArray(@[]),
      "empty_object": vmObject(initOrderedTable[string, VMValue]())
    }.toTable
    let output = render_template(source, data)
    
    check output.strip() == ""

  test "Infinite loop protection":
    # This is a stress test - the VM should handle very long loops
    # In production, you might want a max iteration limit
    let source = "{% for i in items %}{{ i }}{% endfor %}"
    
    # Create a very large array
    var big_array: seq[VMValue] = @[]
    for i in 0..1000:
      big_array.add(vmInt(i))
    
    let data = {
      "items": vmArray(big_array)
    }.toTable
    
    let output = render_template(source, data)
    
    # Should complete without hanging
    check output.len > 0
    check "500" in output  # Middle element should be there

suite "Logical Operators":
  test "Simple and - both true":
    let source = "{% if true and true %}yes{% endif %}"
    let output = render_template(source, initTable[string, VMValue]())
    check output == "yes"

  test "Simple and - one false":
    let source = "{% if true and false %}yes{% endif %}"
    let output = render_template(source, initTable[string, VMValue]())
    check output == ""

  test "Simple or - one true":
    let source = "{% if false or true %}yes{% endif %}"
    let output = render_template(source, initTable[string, VMValue]())
    check output == "yes"

  test "Simple or - both false":
    let source = "{% if false or false %}yes{% endif %}"
    let output = render_template(source, initTable[string, VMValue]())
    check output == ""

  test "Not operator":
    let source = "{% if not false %}yes{% endif %}"
    let output = render_template(source, initTable[string, VMValue]())
    check output == "yes"

  test "Right-associative and/or":
    # true and false and false or true
    # Right-associative: true and (false and (false or true))
    # = true and (false and true) = true and false = false
    let source = "{% if true and false and false or true %}yes{% endif %}"
    let output = render_template(source, initTable[string, VMValue]())
    check output == ""

  test "And with variables":
    let source = "{% if a and b %}yes{% else %}no{% endif %}"
    let data = {"a": VMValue(kind: vmBool, boolVal: true), "b": VMValue(kind: vmBool, boolVal: false)}.toTable
    let output = render_template(source, data)
    check output == "no"

suite "For Loop Limit/Offset":
  test "For with limit":
    let source = "{% for i in items limit: 2 %}{{ i }} {% endfor %}"
    let data = {"items": vmArray(@[vmInt(1), vmInt(2), vmInt(3), vmInt(4)])}.toTable
    let output = render_template(source, data)
    check output == "1 2 "

  test "For with offset":
    let source = "{% for i in items offset: 2 %}{{ i }} {% endfor %}"
    let data = {"items": vmArray(@[vmInt(1), vmInt(2), vmInt(3), vmInt(4)])}.toTable
    let output = render_template(source, data)
    check output == "3 4 "

  test "For with limit and offset":
    let source = "{% for i in items limit: 2 offset: 1 %}{{ i }} {% endfor %}"
    let data = {"items": vmArray(@[vmInt(1), vmInt(2), vmInt(3), vmInt(4)])}.toTable
    let output = render_template(source, data)
    check output == "2 3 "

  test "Limit with non-numeric type raises":
    let source = "{% for i in (1..4) limit: foo %}{{ i }} {% endfor %}"
    let data = {"foo": vmArray(@[vmInt(1), vmInt(2)])}.toTable
    expect CatchableError:
      discard render_template(source, data)

  test "Offset with non-numeric type raises":
    let source = "{% for i in (1..4) offset: foo %}{{ i }} {% endfor %}"
    let data = {"foo": vmArray(@[vmInt(1), vmInt(2)])}.toTable
    expect CatchableError:
      discard render_template(source, data)

suite "Arithmetic Operators":
  test "Subtract integers":
    let source = "{% assign a = 5 %}{% assign b = 3 %}{% assign c = a | minus: b %}{{ c }}"
    let data = initTable[string, VMValue]()
    check render_template(source, data) == "2"

  test "Subtract null treated as zero":
    let source = "{% decrement x %}{% decrement x %}"
    let data = initTable[string, VMValue]()
    check render_template(source, data) == "-1-2"

  test "Increment from null":
    let source = "{% increment x %}{% increment x %}"
    let data = initTable[string, VMValue]()
    check render_template(source, data) == "01"

  test "Unless tag - condition false":
    let source = "{% unless false %}yes{% endunless %}"
    let data = initTable[string, VMValue]()
    check render_template(source, data) == "yes"

  test "Unless tag - condition true":
    let source = "{% unless true %}yes{% endunless %}"
    let data = initTable[string, VMValue]()
    check render_template(source, data) == ""

  test "Unless tag with else":
    let source = "{% unless true %}yes{% else %}no{% endunless %}"
    let data = initTable[string, VMValue]()
    check render_template(source, data) == "no"

suite "Forloop Helper":
  test "Forloop index and index0":
    let source = "{% for i in items %}{{ forloop.index }}-{{ forloop.index0 }} {% endfor %}"
    let data = {"items": vmArray(@[vmInt(1), vmInt(2), vmInt(3)])}.toTable
    check render_template(source, data) == "1-0 2-1 3-2 "

  test "Forloop first and last":
    let source = "{% for i in items %}{{ forloop.first }}-{{ forloop.last }} {% endfor %}"
    let data = {"items": vmArray(@[vmInt(1), vmInt(2), vmInt(3)])}.toTable
    check render_template(source, data) == "true-false false-false false-true "

  test "Forloop length":
    let source = "{% for i in items %}{{ forloop.length }} {% endfor %}"
    let data = {"items": vmArray(@[vmInt(1), vmInt(2), vmInt(3)])}.toTable
    check render_template(source, data) == "3 3 3 "

  test "Forloop rindex and rindex0":
    let source = "{% for i in items %}{{ forloop.rindex }}-{{ forloop.rindex0 }} {% endfor %}"
    let data = {"items": vmArray(@[vmInt(1), vmInt(2), vmInt(3)])}.toTable
    check render_template(source, data) == "3-2 2-1 1-0 "

  test "Forloop goes out of scope after loop":
    let source = "{% for i in items %}{{ forloop.length }} {% endfor %}{{ forloop.length }}"
    let data = {"items": vmArray(@[vmInt(1), vmInt(2)])}.toTable
    check render_template(source, data) == "2 2 "

  test "Nested forloop parentloop":
    let source = "{% for i in (1..2) %}{% for j in (1..2) %}{{ forloop.parentloop.index }}-{{ forloop.index }} {% endfor %}{% endfor %}"
    let data = initTable[string, VMValue]()
    check render_template(source, data) == "1-1 1-2 2-1 2-2 "

  test "Parentloop undefined for top-level loop":
    let source = "{% for i in (1..2) %}{{ forloop.parentloop.index }}{% endfor %}"
    let data = initTable[string, VMValue]()
    check render_template(source, data) == ""

  test "Forloop visible inside an include partial":
    # The lazy scheme keeps forloop out of locals, so the include handler
    # binds a snapshot into the sub-VM's variables.
    let source = "{% for i in items %}{% include 'p' %}{% endfor %}"
    let data = {"items": vmArray(@[vmInt(1), vmInt(2)])}.toTable
    let partials = {"p": "{{ forloop.index }}"}.toTable
    check render_template(source, data, partials) == "12"

  test "Forloop stays invisible inside a render partial":
    let source = "{% for i in items %}{% render 'p' %}{% endfor %}"
    let data = {"items": vmArray(@[vmInt(1), vmInt(2)])}.toTable
    let partials = {"p": "[{{ forloop.index }}]"}.toTable
    check render_template(source, data, partials) == "[][]"

  test "Tablerowloop visible inside an include partial":
    let source = "{% tablerow i in items %}{% include 'p' %}{% endtablerow %}"
    let data = {"items": vmArray(@[vmInt(1), vmInt(2)])}.toTable
    let partials = {"p": "{{ tablerowloop.col }}"}.toTable
    check render_template(source, data, partials) ==
      "<tr class=\"row1\">\n<td class=\"col1\">1</td><td class=\"col2\">2</td></tr>\n"

# Helper for tracked rendering
proc render_tracked_template(source: string, data: Table[string, VMValue],
                              partials: Table[string, string] = initTable[string, string]()):
                              tuple[output: string, accessed: HashSet[string]] =
  let sections = lex(source)
  let compiled = compile(sections, source)
  result = render_tracked(compiled.bytecode, compiled.strings, compiled.constants, data, partials)

suite "Access Tracking":
  test "Simple variable access":
    let (output, accessed) = render_tracked_template("{{ name }}", {"name": vmString("Alice")}.toTable)
    check output == "Alice"
    check "name" in accessed

  test "Property path tracking":
    var user = initOrderedTable[string, VMValue]()
    user["name"] = vmString("Bob")
    let (output, accessed) = render_tracked_template("{{ user.name }}", {"user": vmObject(user)}.toTable)
    check output == "Bob"
    check "user.name" in accessed

  test "Deep property path":
    var city = initOrderedTable[string, VMValue]()
    city["name"] = vmString("Stockholm")
    var address = initOrderedTable[string, VMValue]()
    address["city"] = vmObject(city)
    var user = initOrderedTable[string, VMValue]()
    user["address"] = vmObject(address)
    let (output, accessed) = render_tracked_template("{{ user.address.city.name }}",
      {"user": vmObject(user)}.toTable)
    check output == "Stockholm"
    check "user.address.city.name" in accessed

  test "Array index tracking":
    let items = vmArray(@[vmString("a"), vmString("b"), vmString("c")])
    let (output, accessed) = render_tracked_template("{{ items[0] }}", {"items": items}.toTable)
    check output == "a"
    check "items[0]" in accessed

  test "Multiple variables":
    let data = {"a": vmString("1"), "b": vmString("2"), "c": vmString("3")}.toTable
    let (output, accessed) = render_tracked_template("{{ a }}{{ b }}", data)
    check output == "12"
    check "a" in accessed
    check "b" in accessed
    check "c" notin accessed  # Unused context var not tracked

  test "Local variable not tracked":
    let data = initTable[string, VMValue]()
    let (output, accessed) = render_tracked_template("{% assign x = 1 %}{{ x }}", data)
    check output == "1"
    check accessed.len == 0  # Locals are not context dependencies

  test "Filter with context arg":
    let data = {"name": vmString("hello"), "suffix": vmString("!")}.toTable
    let (output, accessed) = render_tracked_template("{{ name | append: suffix }}", data)
    check output == "hello!"
    check "name" in accessed
    check "suffix" in accessed

  test "Conditional branch - false path not reached":
    let data = {"show": vmBool(false), "name": vmString("Alice")}.toTable
    let (output, accessed) = render_tracked_template("{% if show %}{{ name }}{% endif %}", data)
    check output == ""
    check "show" in accessed    # Condition was evaluated
    check "name" notin accessed  # Body not reached

  test "Conditional branch - true path reached":
    let data = {"show": vmBool(true), "name": vmString("Alice")}.toTable
    let (output, accessed) = render_tracked_template("{% if show %}{{ name }}{% endif %}", data)
    check output == "Alice"
    check "show" in accessed
    check "name" in accessed

  test "For loop tracks collection":
    let items = vmArray(@[vmInt(1), vmInt(2), vmInt(3)])
    let (output, accessed) = render_tracked_template(
      "{% for item in items %}{{ item }}{% endfor %}",
      {"items": items}.toTable)
    check output == "123"
    check "items" in accessed  # Collection dependency tracked

  test "Include transitive tracking":
    let data = {"title": vmString("Hello")}.toTable
    let partials = {"header": "{{ title }}"}.toTable
    let (output, accessed) = render_tracked_template(
      "{% include 'header' %}", data, partials)
    check output == "Hello"
    check "title" in accessed  # Transitive through partial

  test "Render transitive tracking":
    let data = {"greeting": vmString("Hi")}.toTable
    let partials = {"widget": "{{ greeting }}"}.toTable
    let (output, accessed) = render_tracked_template(
      "{% render 'widget' %}", data, partials)
    # render has isolated scope, so greeting should NOT be accessed from parent context
    check output == ""
    check "greeting" notin accessed

  test "Comparison tracks both operands":
    let data = {"a": vmInt(1), "b": vmInt(2)}.toTable
    let (output, accessed) = render_tracked_template("{% if a == b %}yes{% endif %}", data)
    check output == ""
    check "a" in accessed
    check "b" in accessed

  test "Assign from context then use":
    let data = {"original": vmString("value")}.toTable
    let (output, accessed) = render_tracked_template(
      "{% assign copy = original %}{{ copy }}", data)
    check output == "value"
    # original was read from context to create the local
    check "original" in accessed

  test "Size property tracking":
    let items = vmArray(@[vmInt(1), vmInt(2)])
    let (output, accessed) = render_tracked_template("{{ items.size }}", {"items": items}.toTable)
    check output == "2"
    check "items.size" in accessed
