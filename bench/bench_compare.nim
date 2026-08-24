## Compare two bench_vm --json snapshots.
##
##   nim c -r -d:release bench/bench_vm.nim --json > /tmp/before.json
##   # ...change the VM...
##   nim c -r -d:release bench/bench_vm.nim --json > /tmp/after.json
##   nim c -r bench/bench_compare.nim /tmp/before.json /tmp/after.json
##
## A negative percentage means the second run is faster.

import std/[json, os, tables, strutils, strformat]

when isMainModule:
  if paramCount() < 2:
    echo "usage: bench_compare <before.json> <after.json>"
    quit(1)

  proc load(path: string): OrderedTable[string, float] =
    result = initOrderedTable[string, float]()
    for r in parseFile(path)["results"]:
      result[r["name"].getStr] = r["ns_per_render"].getFloat

  let before = load(paramStr(1))
  let after = load(paramStr(2))

  echo ""
  echo &"{\"workload\":<20} {\"before\":>12} {\"after\":>12} {\"change\":>10}"
  echo "─".repeat(58)

  var sum_before = 0.0
  var sum_after = 0.0

  proc fmt(ns: float): string =
    if ns >= 1_000_000.0: &"{ns / 1_000_000.0:.3f} ms"
    elif ns >= 1_000.0:   &"{ns / 1_000.0:.2f} us"
    else:                 &"{ns:.1f} ns"

  for name, b in before:
    if name notin after: continue
    let a = after[name]
    sum_before += b
    sum_after += a
    let pct = (a - b) / b * 100.0
    let mark =
      if pct <= -5.0: "  faster"
      elif pct >= 5.0: "  SLOWER"
      else: ""
    echo &"{name:<20} {fmt(b):>12} {fmt(a):>12} {pct:>9.1f}%{mark}"

  echo "─".repeat(58)
  let total_pct = (sum_after - sum_before) / sum_before * 100.0
  echo &"{\"total\":<20} {fmt(sum_before):>12} {fmt(sum_after):>12} {total_pct:>9.1f}%"
  echo ""
