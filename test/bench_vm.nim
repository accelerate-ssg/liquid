## VM throughput benchmark
## ========================
##
## Measures *render* time only — every template is lexed and compiled once,
## outside the timing loop, so the numbers track VM work rather than
## front-end work. Each workload isolates one hot path so a change can be
## attributed to the thing it was meant to speed up.
##
## Run with:
##   nim c -r -d:release test/bench_vm.nim
##
## Compare two builds:
##   nim c -r -d:release test/bench_vm.nim --json > before.json
##   ...edit the VM...
##   nim c -r -d:release test/bench_vm.nim --json > after.json
##   nim c -r test/bench_compare.nim before.json after.json

import std/[times, tables, strutils, strformat, os, algorithm, json]

import ../src/liquid/[lexer, compiler, vm]
import ../src/liquid/compiler/types
import ../src/liquid/vm/types as vm_types

# ─── Workload data ────────────────────────────────────────────────────

proc make_products(n: int): VMValue =
  var items: seq[VMValue] = @[]
  for i in 0 ..< n:
    items.add(vm_object({
      "id": vm_int(i.int64),
      "title": vm_string("Product number " & $i),
      "price": vm_int((i * 37 mod 990 + 10).int64),
      "sku": vm_string("SKU-" & align($i, 6, '0')),
      "available": vm_bool(i mod 3 != 0),
      "vendor": vm_object({
        "name": vm_string("Vendor " & $(i mod 17)),
        "country": vm_string("SE"),
      }.toOrderedTable),
      "tags": vm_array(@[
        vm_string("tag-" & $(i mod 5)),
        vm_string("tag-" & $(i mod 7)),
      ]),
    }.toOrderedTable))
  vm_array(items)

proc make_context(): Table[string, VMValue] =
  result = initTable[string, VMValue]()
  result["products"] = make_products(100)
  result["shop"] = vm_object({
    "name": vm_string("Test & Shop <fancy>"),
    "currency": vm_string("SEK"),
    "settings": vm_object({
      "theme": vm_object({
        "colors": vm_object({
          "primary": vm_string("#ff0000"),
        }.toOrderedTable),
      }.toOrderedTable),
    }.toOrderedTable),
  }.toOrderedTable)
  result["title"] = vm_string("A plain title with no markup at all")
  result["html_title"] = vm_string("A <b>bold</b> & \"quoted\" title")
  result["count"] = vm_int(42)
  result["flag"] = vm_bool(true)
  result["words"] = vm_string("the quick brown fox jumps over the lazy dog")

# ─── Workloads ────────────────────────────────────────────────────────

type Workload = object
  name: string
  source: string
  partials: Table[string, string]
  iterations: int

proc wl(name, source: string, iterations: int,
        partials: Table[string, string] = initTable[string, string]()): Workload =
  Workload(name: name, source: source, partials: partials, iterations: iterations)

proc workloads(): seq[Workload] =
  result = @[]

  # Empty template: pure per-render setup cost. Every other number below
  # includes this floor, so read them as "floor + the work being measured".
  result.add wl("empty", "", 20000)

  # Pure literal passthrough: isolates output emission with zero expression work.
  result.add wl("literal-text", "Lorem ipsum dolor sit amet. ".repeat(40), 20000)

  # The single most common Liquid shape: loop + property access + output.
  result.add wl("loop-property", """
{% for p in products %}{{ p.title }}|{{ p.price }}|{{ p.sku }}
{% endfor %}""", 2000)

  # forloop.* metadata on every iteration — stresses per-iteration bookkeeping.
  result.add wl("loop-forloop-meta", """
{% for p in products %}{{ forloop.index }}/{{ forloop.length }}{% if forloop.first %}F{% endif %}{% if forloop.last %}L{% endif %}
{% endfor %}""", 2000)

  # Loop body that touches nothing — isolates iteration overhead itself.
  result.add wl("loop-empty-body", "{% for p in products %}x{% endfor %}", 5000)

  # Nested loops: forloop nesting, parentloop, iterator stack churn.
  result.add wl("loop-nested", """
{% for p in products %}{% for t in p.tags %}{{ t }}{% endfor %}{% endfor %}""", 1000)

  # Deep chained property access through nested objects.
  result.add wl("deep-property",
    "{{ shop.settings.theme.colors.primary }}".repeat(20), 5000)

  # Simple variable resolution, repeated — isolates resolve_var.
  result.add wl("var-resolve", "{{ title }}".repeat(40), 10000)

  # Filter dispatch and argument handling.
  result.add wl("filters", """
{{ words | upcase }}{{ words | split: " " | first }}{{ count | plus: 1 | times: 2 }}{{ title | truncate: 10 }}{{ words | replace: "quick", "slow" }}""", 5000)

  # Filters applied inside a loop — the realistic combination.
  result.add wl("loop-filters", """
{% for p in products %}{{ p.title | upcase | truncate: 20 }}{{ p.price | times: 100 }}{% endfor %}""", 1000)

  # Output that actually needs HTML escaping vs output that does not.
  result.add wl("escape-heavy", "{{ html_title }}".repeat(40), 10000)
  result.add wl("escape-none", "{{ title }}".repeat(40), 10000)

  # Conditionals and comparisons.
  result.add wl("conditionals", """
{% for p in products %}{% if p.price > 500 %}hi{% elsif p.price > 100 %}mid{% else %}lo{% endif %}{% unless p.available %}!{% endunless %}{% endfor %}""", 2000)

  # assign / capture — locals table churn.
  result.add wl("assign-capture", """
{% for p in products %}{% assign n = p.title %}{% capture c %}{{ n }}-{{ p.id }}{% endcapture %}{{ c }}{% endfor %}""", 1000)

  # Partials: sub-VM construction cost per include.
  var partials = initTable[string, string]()
  partials["card"] = "{{ p.title }} costs {{ p.price }}"
  result.add wl("include-partial", """
{% for p in products %}{% include "card" %}{% endfor %}""", 500, partials)

  # Range iteration and arithmetic.
  result.add wl("range-loop", "{% for i in (1..200) %}{{ i }},{% endfor %}", 2000)

  # tablerow tag.
  result.add wl("tablerow", "{% tablerow p in products cols:4 %}{{ p.title }}{% endtablerow %}", 1000)

  # A composite "real page" mixing everything.
  result.add wl("realistic-page", """
<h1>{{ shop.name }}</h1>
<ul>
{% for p in products %}
  <li class="{% if forloop.first %}first{% endif %}">
    <a href="/p/{{ p.sku | downcase }}">{{ p.title | truncate: 30 }}</a>
    <span>{{ p.price }} {{ shop.currency }}</span>
    {% if p.available %}<em>In stock</em>{% else %}<em>Sold out</em>{% endif %}
    {% for t in p.tags %}<b>{{ t }}</b>{% endfor %}
  </li>
{% endfor %}
</ul>
<footer>{{ shop.settings.theme.colors.primary }}</footer>""", 500)

# ─── Timing ───────────────────────────────────────────────────────────

type Result = object
  name: string
  ns_per_render: float
  renders_per_sec: float
  output_bytes: int

proc bench(w: Workload, ctx: Table[string, VMValue]): Result =
  # Compile once — we are measuring the VM, not the front end.
  let sections = lex(w.source)
  let compiled = compile(sections, w.source, false)

  # Warm up: lets the allocator settle and the branch predictors train.
  var sink = 0
  for _ in 0 ..< max(w.iterations div 10, 5):
    sink += render(compiled.bytecode, compiled.strings, compiled.constants,
                   ctx, w.partials).len

  # Three samples, keep the best: the fastest run is the one least
  # disturbed by other work on the machine.
  var best = Inf
  var bytes = 0
  for sample in 0 ..< 3:
    let t0 = cpuTime()
    for _ in 0 ..< w.iterations:
      bytes = render(compiled.bytecode, compiled.strings, compiled.constants,
                     ctx, w.partials).len
      sink += bytes
    let elapsed = cpuTime() - t0
    let per = elapsed * 1_000_000_000.0 / w.iterations.float
    if per < best: best = per

  doAssert sink >= 0  # keep the optimizer honest
  Result(name: w.name, ns_per_render: best,
         renders_per_sec: 1_000_000_000.0 / best, output_bytes: bytes)

# ─── Main ─────────────────────────────────────────────────────────────

proc fmt_ns(ns: float): string =
  if ns >= 1_000_000.0: &"{ns / 1_000_000.0:>8.3f} ms"
  elif ns >= 1_000.0:   &"{ns / 1_000.0:>8.3f} us"
  else:                 &"{ns:>8.1f} ns"

when isMainModule:
  var as_json = false
  var filter = ""
  for i in 1 .. paramCount():
    let p = paramStr(i)
    if p == "--json": as_json = true
    else: filter = p

  let ctx = make_context()
  var results: seq[Result] = @[]

  for w in workloads():
    if filter.len > 0 and filter notin w.name: continue
    results.add bench(w, ctx)

  if as_json:
    var arr = newJArray()
    for r in results:
      arr.add(%*{
        "name": r.name,
        "ns_per_render": r.ns_per_render,
        "renders_per_sec": r.renders_per_sec,
        "output_bytes": r.output_bytes,
      })
    echo pretty(%*{"results": arr})
  else:
    echo ""
    echo "workload              time/render     renders/sec   out bytes"
    echo "─".repeat(62)
    var total = 0.0
    for r in results:
      total += r.ns_per_render
      echo &"{r.name:<20} {fmt_ns(r.ns_per_render)}  {r.renders_per_sec:>13.0f}   {r.output_bytes:>9}"
    echo "─".repeat(62)
    echo &"{\"sum of all\":<20} {fmt_ns(total)}"
    echo ""
