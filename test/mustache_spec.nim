# Official Mustache spec conformance suite
# ========================================
# Runs the vendored https://github.com/mustache/spec JSON suites against
# the Mustache tine. The optional ~lambdas and ~inheritance modules are
# not vendored (lambdas are deliberately out of scope for now).

import std/[json, os, tables, strutils]
import ../src/mustache_lib

const suites = ["interpolation", "sections", "inverted", "comments",
                "delimiters", "partials"]

var run = 0
var passed = 0
var failures: seq[string] = @[]

for suite in suites:
  let path = currentSourcePath().parentDir() / "mustache_spec" / suite & ".json"
  let spec = parseJson(readFile(path))
  for t in spec["tests"]:
    inc run
    let name = suite & " :: " & t["name"].getStr()
    let templ = t["template"].getStr()
    let data = t["data"]
    var partials = initTable[string, string]()
    if "partials" in t:
      for k, v in t["partials"]:
        partials[k] = v.getStr()
    let expected = t["expected"].getStr()
    var got: string
    try:
      got = render(templ, data, partials)
    except CatchableError as e:
      failures.add(name & "\n  ERROR: " & e.msg)
      continue
    if got == expected:
      inc passed
    else:
      failures.add(name &
        "\n  template: " & templ.escape() &
        "\n  expected: " & expected.escape() &
        "\n  got:      " & got.escape())

for f in failures:
  echo "[FAILED] ", f

echo ""
echo "Mustache spec: ", passed, "/", run, " passed"
if passed != run:
  quit(1)
