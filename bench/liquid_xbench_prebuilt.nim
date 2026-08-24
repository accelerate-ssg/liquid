# Pitchfork prebuilt-context path: JSON converted once, precompiled templates.
import std/[json, monotimes, times, tables, strutils]
import ../src/pitchfork/json_bridge
import ../src/pitchfork/tines/liquid/api

const small_tmpl = "Hello {{ name }}, you have {{ count }} new {% if plural %}messages{% else %}message{% endif %}."
const page_tmpl = """<html><head><title>{{ title }}</title></head><body>
<h1>{{ title }}</h1>
{% for product in products %}
  <div class="product">
    <h2>{{ product.name }}</h2>
    <p>{{ product.description }}</p>
    <span class="price">{{ product.price }}</span>
    <ul>{% for tag in product.tags %}<li>{{ tag }}</li>{% endfor %}</ul>
    {% if product.inStock %}<b>In stock</b>{% else %}<i>Sold out</i>{% endif %}
  </div>
{% endfor %}
</body></html>
"""

proc page_data(n: int): JsonNode =
  var products = newJArray()
  for i in 0 ..< n:
    products.add(%*{
      "name": "Product " & $i,
      "description": "A fine product and a bargain no. " & $i,
      "price": 999 + i,
      "tags": ["new", "sale", "tag" & $(i mod 7)],
      "inStock": i mod 2 == 0,
    })
  %*{"title": "Catalog", "products": products}

var blackhole = 0
template bench(label: string, iterations: int, body: untyped) =
  block:
    for _ in 0 ..< max(iterations div 10, 1): body
    let start = getMonoTime()
    for _ in 0 ..< iterations: body
    let elapsed_us = (getMonoTime() - start).inNanoseconds.float / 1e3
    stdout.write(label & "\t" & formatFloat(elapsed_us / iterations.float, ffDecimal, 2) & " us/render\n")

let s_table = json_to_vm_table(%*{"name": "Alice", "count": 3, "plural": true})
let p_table = json_to_vm_table(page_data(100))
let no_partials = initTable[string, string]()

let cs = compile_source(small_tmpl)
let cp = compile_source(page_tmpl)
echo "checksum small=", render(cs.bytecode, cs.strings, cs.constants, s_table, no_partials).len,
     " page=", render(cp.bytecode, cp.strings, cp.constants, p_table, no_partials).len

bench("prebuilt small", 100_000):
  blackhole += render(cs.bytecode, cs.strings, cs.constants, s_table, no_partials).len
bench("prebuilt page ", 2_000):
  blackhole += render(cp.bytecode, cp.strings, cp.constants, p_table, no_partials).len
echo "(", blackhole, ")"
