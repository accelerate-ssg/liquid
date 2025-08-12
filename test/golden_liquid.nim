import times, os, strutils, sets, tables
import helpers

resetOutputFormatters()
addOutputFormatter(formatter)

# Load test groups from JSON file
let jsonPath = currentSourcePath().parentDir() / "golden_liquid.json"
let jsonContent = readFile(jsonPath)
let testData = parseJson(jsonContent)

let enabledSuits = [
  "assign tag",
  "capture tag",
  "case tag",
  "comment tag",
  "cycle tag",
  "decrement tag",
  "echo tag",
  "for tag",
  "identifiers",
  "if tag",
  "ifchanged tag",
  "illegal",
  "include tag",
  "increment tag",
  #"inline comment tag",
  #"liquid tag",
  "not liquid",
  "output statement",
  "range objects",
  "raw tag",
  "render tag",
  "special",
  "tablerow tag",
  "unless tag",
  "whitespace control"
].toHashSet()

let t0 = cpuTime()

# Run tests from JSON
for testGroup in testData["test_groups"]:
  let groupName = testGroup["name"].getStr()
  # Extract suite name from group name (e.g., "liquid.golden.assign_tag" -> "assign tag")
  let suiteName = groupName.replace("liquid.golden.", "").replace("_", " ")
  
  # Skip disabled test groups
  if suiteName notin enabledSuits:
    continue
  
  suite suiteName:
    for test in testGroup["tests"]:
      let name = test["name"].getStr()
      let source = test["template"].getStr()
      let want = test["want"].getStr()
      let context = test["context"]
      let partials = if test.hasKey("partials"):
        var p = initTable[string, string]()
        for key, val in test["partials"]:
          p[key] = val.getStr()
        p
      else:
        initTable[string, string]()
      let error = test["error"].getBool()
      let strict = test["strict"].getBool()
      
      testCase(name, source, context, want, partials, error, strict)

let t1 = cpuTime()
let duration = t1 - t0

let failures = getFailures()
let failuresCount = failures.len
let sucessesCount = getSuccesses()
let totalCount = failuresCount + sucessesCount;

# Print failure summary
if failuresCount > 0:
  echo "\nFailures:"
  var suiteName = ""
  for failure in failures:
    if failure.suiteName != suiteName:
      suiteName = failure.suiteName
      echo "\n  " & suiteName
    echo "    " & failure.testName
  echo ""
  echo "Duration: " & $duration & " seconds"
  echo "Total tests: " & $totalCount & ", Successes: " & $sucessesCount & ", Failures: " & $failuresCount
  quit(1)
else:
  echo "Duration: " & $duration & " seconds"
  echo "All " & $totalCount & " tests passed!"
  quit(0)
