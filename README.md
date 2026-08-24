# Pitchfork

A multi-language template engine for Nim: several parser frontends
("tines") uniting into one common bytecode VM (the handle).

Liquid is the first supported template language; Mustache and Handlebars
frontends are planned. The original Liquid API (`liquid_lib`) is unchanged.

## Architecture

```
src/pitchfork/              engine core (language-agnostic)
  bytecode.nim              instruction set, VMValue, CompileResult
  emitter.nim               generic bytecode emission (Emitter base object)
  values.nim                value ops + filter registry
  vm.nim, vm_types.nim      the stack VM
  json_bridge.nim           JsonNode <-> VMValue
src/pitchfork/tines/liquid/ the Liquid frontend
  lexer.nim, compiler.nim   Liquid source -> bytecode
  runtime.nim               runtime tag handlers (cycle, tablerow, ...)
  filters/                  built-in Liquid filters
  api.nim                   wires it all onto a VM
src/liquid_lib.nim          stable JsonNode-based public API
```

A tine compiles its language to the shared bytecode; the VM knows nothing
about any particular template language — language specifics reach it through
registered tag handlers, the filter registry, and a `partial_compiler`
callback so partials compile in the including template's language.

## Installation

This package is not on the Nimble registry; install it directly from Git.

In your project's `.nimble` file:

```nim
requires "https://github.com/accelerate-ssg/liquid"
```

Or, ad-hoc:

```sh
nimble install https://github.com/accelerate-ssg/liquid
```

Requires Nim `>= 2.0.0`.

## Usage (Liquid)

The public API lives in `liquid_lib`. It takes a `JsonNode` for the
template context and returns the rendered string.

```nim
import json
import liquid_lib

let ctx = %*{"name": "World"}
echo render("Hello, {{ name }}!", ctx)
# => Hello, World!
```

### Nested context, arrays, filters, conditionals

```nim
import json
import liquid_lib

let ctx = %*{
  "user": {"name": "Alice", "age": 30},
  "items": ["a", "b", "c"],
  "show": true,
}

echo render("{{ user.name | upcase }} is {{ user.age }}", ctx)
# => ALICE is 30

echo render("{% for item in items %}{{ item }},{% endfor %}", ctx)
# => a,b,c,

echo render("{% if show %}visible{% endif %}", ctx)
# => visible
```

### Partials (`{% include %}` / `{% render %}`)

Partials are passed as a `Table[string, string]` mapping name to source.

```nim
import json, tables
import liquid_lib

let ctx = %*{"title": "Hello"}
let partials = {"header": "<h1>{{ title }}</h1>"}.toTable

echo render("{% include 'header' %}", ctx, partials)
# => <h1>Hello</h1>
```

### Pre-compiling a template for reuse

If you render the same template multiple times, compile it once.

```nim
import json
import liquid_lib

let tmpl = compile_template("Hello, {{ name }}!")

echo tmpl.render(%*{"name": "Alice"})  # => Hello, Alice!
echo tmpl.render(%*{"name": "Bob"})    # => Hello, Bob!
```

### Tracking which context paths were read

`render_tracked` returns the rendered string plus the set of context
variable paths that were accessed. Useful for dependency tracking and
incremental rebuilds.

```nim
import json
import liquid_lib

let ctx = %*{"a": 1, "b": 2, "c": 3}
let (output, accessed) = render_tracked("{{ a }}{{ b }}", ctx)

echo output            # => 12
echo "a" in accessed   # => true
echo "c" in accessed   # => false
```

The compiled-template form has the same overload:

```nim
let tmpl = compile_template("{{ a }}{{ b }}")
let (output, accessed) = tmpl.render_tracked(ctx)
```

## C library

A C-callable shared library is also available. Build it from a checkout
of this repo with:

```sh
nimble clib
```

This produces `libliquid.dylib` (or `.so` / `.dll` depending on platform)
with `liquid_render`, `liquid_free`, and `liquid_init` exports. See
`src/liquid_c.nim` for the exact C signatures.

## License

MIT.
