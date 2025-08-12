import times, os, strutils, sets, tables
import golden_liquid/helpers

resetOutputFormatters()
addOutputFormatter(formatter)

let t0 = cpuTime()

# Load test groups from JSON file
let jsonPath = currentSourcePath().parentDir() / "golden_liquid.json"
let jsonContent = readFile(jsonPath)
let testData = parseJson(jsonContent)

# Enabled test groups - matching the previously included test files
let enabledGroups = [
  "liquid.golden.assign_tag",
  "liquid.golden.capture_tag",
  "liquid.golden.case_tag",
  "liquid.golden.comment_tag",
  "liquid.golden.cycle_tag",
  "liquid.golden.decrement_tag",
  "liquid.golden.echo_tag",
  "liquid.golden.for_tag",
  "liquid.golden.identifiers",
  "liquid.golden.if_tag",
  "liquid.golden.ifchanged_tag",
  "liquid.golden.illegal",
  "liquid.golden.include_tag",
  "liquid.golden.increment_tag",
  "liquid.golden.inline_comment_tag",
  "liquid.golden.liquid_tag",
  "liquid.golden.not_liquid",
  "liquid.golden.output_statement",
  "liquid.golden.range_objects",
  "liquid.golden.raw_tag",
  "liquid.golden.render_tag",
  "liquid.golden.special",
  "liquid.golden.tablerow_tag",
  "liquid.golden.unless_tag",
  "liquid.golden.whitespace_control"
].toHashSet()

# Run tests from JSON
for testGroup in testData["test_groups"]:
  let groupName = testGroup["name"].getStr()
  
  # Skip disabled test groups
  if groupName notin enabledGroups:
    continue
    
  # Extract suite name from group name (e.g., "liquid.golden.assign_tag" -> "assign tag")
  let suiteName = groupName.replace("liquid.golden.", "").replace("_", " ")
  
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
