# Pitchfork

A multi-language template engine for Nim: several parser frontends
("tines") uniting into one common bytecode VM (the handle).

Three template languages are supported so far:

- **Liquid** — the original engine; API (`liquid_lib`) unchanged.
- **Mustache** — fully conformant with the required modules of the official
  [mustache/spec](https://github.com/mustache/spec) suite.
- **Handlebars** — the core feature set: paths (`../`, `this`, segment
  literals), `#if`/`#unless`/`#each`/`#with` with `{{else}}`, plain and
  inverted sections, `@index`/`@key`/`@first`/`@last`/`@root`, registered
  helpers with literal args and subexpressions, partials (context argument,
  hash arguments, standalone indentation, recursion), both comment styles,
  raw blocks, and `~` whitespace control. Not yet: custom block helpers,
  hash arguments on non-partial helpers, dynamic partial names, block
  params (`as |x|`), lambdas. Name resolution follows Handlebars' `compat`
  mode (parent scopes are searched automatically).

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
src/pitchfork/tines/mustache/ the Mustache frontend
  lexer.nim                 tokens, delimiters, standalone-line handling
  compiler.nim              tokens -> bytecode (context-stack semantics)
  api.nim                   wires the VM (partials compile as Mustache)
src/pitchfork/tines/handlebars/ the Handlebars frontend
  lexer.nim                 tags, ~ trimming, raw blocks, standalone lines
  compiler.nim              expression parser (helpers, subexpressions,
                            hash args, parent paths) -> bytecode
  api.nim                   wires the VM; register_helper
src/liquid_lib.nim          stable JsonNode-based public API (Liquid)
src/mustache_lib.nim        JsonNode-based public API (Mustache)
src/handlebars_lib.nim      JsonNode-based public API (Handlebars)
```

A tine compiles its language to the shared bytecode; the VM knows nothing
about any particular template language — language specifics reach it through
registered tag handlers, the filter registry, and a `partial_compiler`
callback so partials compile in the including template's language. Mustache's
scoped lookup rides on the same resolution opcode Liquid uses (`opResolveName`
walks the context stack, then the flat scope chain — for Liquid the context
stack is simply empty), and its sections reuse the standard loop machinery.

Each tine also registers its *truthiness policy* as namespaced filters
(`mustache#section`, `hb#if`, ...) — which values are falsy and what
iterates is language policy, and it lives in the tine, not the engine.
Handlebars helpers are shared-registry filters too: `{{helper a b}}` calls
the filter `helper` with value `a` and args `[b]`, so one registration
mechanism serves Liquid filters and Handlebars helpers alike.

Mustache/Handlebars lambdas are intentionally unsupported for now; the plan
is a registered script-runner hook rather than callables in the data.

## Usage (Handlebars)

```nim
import json, tables
import handlebars_lib

echo render("{{#each items}}{{@index}}:{{this}} {{/each}}",
            %*{"items": ["a", "b"]})
# => 0:a 1:b

import pitchfork/tines/handlebars/api
register_helper("shout", proc(value: VMValue, args: varargs[VMValue]): VMValue =
  vm_string(to_string(value) & "!"))
echo render("{{shout name}}", %*{"name": "hey"})
# => hey!
```

## Usage (Mustache)

```nim
import json, tables
import mustache_lib

echo render("Hello, {{name}}!", %*{"name": "World"})
# => Hello, World!

echo render("{{#items}}({{.}}){{/items}}", %*{"items": ["a", "b"]})
# => (a)(b)

let partials = {"user": "<li>{{name}}</li>"}.toTable
echo render("<ul>{{#users}}{{>user}}{{/users}}</ul>",
            %*{"users": [{"name": "A"}, {"name": "B"}]}, partials)
# => <ul><li>A</li><li>B</li></ul>
```

`render_tracked`, `compile_template`, and pre-compiled `render` mirror the
Liquid API below.

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
