# Liquid Library API
# ==================
# Clean public API for the Liquid template engine.
# Accepts JsonNode context data and returns rendered strings.

import std/[json, tables, sets]
import liquid/[lexer, compiler, vm, json_bridge]
import liquid/compiler/types as compiler_types

export json_bridge

proc render*(template_source: string, context: JsonNode,
             partials: Table[string, string] = initTable[string, string]()): string =
  ## Compile and render a Liquid template with JSON context data.
  ##
  ## Parameters:
  ##   template_source: The Liquid template string
  ##   context: A JObject with template variables (keys become top-level variables)
  ##   partials: Optional partial templates (name -> source)
  ##
  ## Returns the rendered output string.
  let sections = lex(template_source)
  let compiled = compile(sections, template_source)
  let data = json_to_vm_table(context)
  result = vm.render(compiled.bytecode, compiled.strings, compiled.constants,
                     data, partials)

type
  CompiledTemplate* = object
    ## A pre-compiled template that can be rendered multiple times
    ## with different context data.
    bytecode: seq[compiler_types.Instruction]
    strings: seq[string]
    constants: seq[compiler_types.VMValue]

proc compile_template*(template_source: string): CompiledTemplate =
  ## Pre-compile a template for repeated rendering.
  let sections = lex(template_source)
  let compiled = compile(sections, template_source)
  result = CompiledTemplate(
    bytecode: compiled.bytecode,
    strings: compiled.strings,
    constants: compiled.constants,
  )

proc render*(compiled: CompiledTemplate, context: JsonNode,
             partials: Table[string, string] = initTable[string, string]()): string =
  ## Render a pre-compiled template with JSON context data.
  let data = json_to_vm_table(context)
  result = vm.render(compiled.bytecode, compiled.strings, compiled.constants,
                     data, partials)

when isMainModule:
  import std/unittest

  suite "Liquid Library API":
    test "render simple template":
      let ctx = %*{"name": "World"}
      let output = render("Hello, {{ name }}!", ctx)
      check output == "Hello, World!"

    test "render with missing variable":
      let ctx = newJObject()
      let output = render("Hello, {{ name }}!", ctx)
      check output == "Hello, !"

    test "render with nested context":
      let ctx = %*{"user": {"name": "Alice", "age": 30}}
      let output = render("{{ user.name }} is {{ user.age }}", ctx)
      check output == "Alice is 30"

    test "render with array":
      let ctx = %*{"items": ["a", "b", "c"]}
      let output = render("{% for item in items %}{{ item }}{% endfor %}", ctx)
      check output == "abc"

    test "render with partials":
      let ctx = %*{"title": "Test"}
      let partials = {"header": "<h1>{{ title }}</h1>"}.toTable
      let output = render("{% include 'header' %}", ctx, partials)
      check output == "<h1>Test</h1>"

    test "compiled template reuse":
      let compiled = compile_template("Hello, {{ name }}!")
      check compiled.render(%*{"name": "Alice"}) == "Hello, Alice!"
      check compiled.render(%*{"name": "Bob"}) == "Hello, Bob!"

    test "json_to_vmvalue null":
      let v = json_to_vmvalue(newJNull())
      check v.kind == vmNull

    test "json_to_vmvalue bool":
      let v = json_to_vmvalue(newJBool(true))
      check v.kind == vmBool
      check v.boolVal == true

    test "json_to_vmvalue int":
      let v = json_to_vmvalue(newJInt(42))
      check v.kind == vmInt
      check v.intVal == 42

    test "json_to_vmvalue float":
      let v = json_to_vmvalue(newJFloat(3.14))
      check v.kind == vmFloat
      check v.floatVal == 3.14

    test "json_to_vmvalue string":
      let v = json_to_vmvalue(newJString("hello"))
      check v.kind == vmString
      check v.stringVal == "hello"

    test "json_to_vmvalue array":
      let v = json_to_vmvalue(%*[1, "two", true])
      check v.kind == vmArray
      check v.arrayVal.len == 3
      check v.arrayVal[0].kind == vmInt
      check v.arrayVal[1].kind == vmString
      check v.arrayVal[2].kind == vmBool

    test "json_to_vmvalue object":
      let v = json_to_vmvalue(%*{"a": 1, "b": "two"})
      check v.kind == vmObject
      check v.objectVal["a"].kind == vmInt
      check v.objectVal["b"].kind == vmString

    test "vmvalue_to_json round-trip":
      let original = %*{
        "name": "Alice",
        "age": 30,
        "active": true,
        "score": 9.5,
        "tags": ["nim", "liquid"],
        "address": {"city": "Stockholm"}
      }
      let vm_val = json_to_vmvalue(original)
      let back = vmvalue_to_json(vm_val)
      check back["name"].getStr == "Alice"
      check back["age"].getInt == 30
      check back["active"].getBool == true
      check back["score"].getFloat == 9.5
      check back["tags"][0].getStr == "nim"
      check back["address"]["city"].getStr == "Stockholm"

    test "json_to_vm_table from non-object":
      let t = json_to_vm_table(newJArray())
      check t.len == 0

    test "json_to_vmvalue nil node":
      let v = json_to_vmvalue(nil)
      check v.kind == vmNull

    test "render with integers and booleans in context":
      let ctx = %*{"count": 3, "active": true}
      let output = render("Count: {{ count }}, Active: {{ active }}", ctx)
      check output == "Count: 3, Active: true"

    test "render with filters":
      let ctx = %*{"name": "hello world"}
      let output = render("{{ name | upcase }}", ctx)
      check output == "HELLO WORLD"

    test "render with conditional":
      let ctx = %*{"show": true, "message": "visible"}
      let output = render("{% if show %}{{ message }}{% endif %}", ctx)
      check output == "visible"
