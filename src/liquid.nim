from posix import onSignal, SIGSEGV
import os, parseopt, json, strutils

import liquid/lexer
import liquid/parser
import liquid/renderer

proc test(source: string, context: JsonNode, expected: string): bool =
  try:
    let sections = lex(source)
    let parsedSections = parse(sections)
    let renderedTemplate = renderSections(parsedSections, context)

    echo "    rendered: \"" & renderedTemplate & "\""
    echo "    expected: \"" & expected & "\""
    return renderedTemplate == expected
  except CatchableError as e:
    echo "  Error: " & e.msg
    return false

var success = 0
var run = 0
var current_test: string = ""
var group_filter: string = ""
var test_filter: string = ""
var optparser = initOptParser(quoteShellCommand(commandLineParams()))

onSignal(SIGSEGV):
  echo "Caught \"SIGSEGV: Illegal storage access. (Attempt to read from nil?)\" while running \"" & current_test & "\", exiting..."
  echo "Ran " & $run & " tests, " & $success & " passed"
  quit(0)

for kind, key, val in optparser.getopt():
  case kind
  of cmdLongOption, cmdShortOption:
    case key
    of "group", "g": group_filter = val
    of "test", "t": test_filter = val
    else: discard
  else:
    echo "Usage: liquid [options]"
    echo "Options:"
    echo "  -g, --group <group>  Run only tests in the specified group"
    echo "  -t, --test <test>    Run only the specified test"
    quit(0)

# Read test/golden_liquid/golden_liquid.json and parse the JSON
let test_groups = parseFile("test/golden_liquid/golden_liquid.json")["test_groups"].getElems()

# Run the tests
for test_group in test_groups:
  let group_name = test_group["name"].getStr()
  if group_filter.len > 0 and not(group_filter in group_name):
    continue
  let tests = test_group["tests"].getElems()
  echo "\n" & group_name & "(" & $tests.len & ")"
  for test_case in tests:
    let
      name = test_case["name"].getStr()
      source = test_case["template"].getStr()
      want = test_case["want"].getStr()
      context = test_case["context"]

    if test_filter.len > 0 and not(test_filter in name):
      continue

    run += 1
    current_test = name

    if test(source, context, want):
      success += 1
      echo "  [PASS] " & name 
    else:
      echo "  [FAIL] " & name

echo "Ran " & $run & " tests, " & $success & " passed"
