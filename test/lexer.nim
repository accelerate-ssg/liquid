import json, strutils, re

import ../src/liquid/lexer_v2

type
  TestCase = object
    name: string
    template_string: string
    want: string

  TestGroup = object
    name: string
    tests: seq[TestCase]

proc parseTestGroups(jsonNode: JsonNode): seq[TestGroup] =
  result = @[]
  for group in jsonNode["test_groups"]:
    var testGroup = TestGroup(name: group["name"].getStr())
    for test in group["tests"]:
      testGroup.tests.add(TestCase(
        name: test["name"].getStr(),
        template_string: test["template"].getStr(),
        want: test["want"].getStr()
      ))
    result.add(testGroup)

proc toTemplate(tokens: seq[Token]): string =
  var line = 1
  result = ""
  for token in tokens:
    if token.line > line:
      result.add("\n")
      line = token.line
    case token.kind
    of tkText: result.add(token.lexem)
    of tkOutputStart: result.add("{{ ")
    of tkOutputStartTrim: result.add("{{- ")
    of tkOutputEnd: result.add(" }}")
    of tkOutputEndTrim: result.add(" -}}")
    of tkTagStart: result.add("{% ")
    of tkTagStartTrim: result.add("{%- ")
    of tkTagEnd: result.add(" %}")
    of tkTagEndTrim: result.add(" -%}")
    of tkString: result.add("\"" & token.lexem & "\"")
    of tkNumber, tkIdentifier, tkBoolean, tkNil: result.add(token.lexem)
    of tkPipe: result.add(" | ")
    of tkColon: result.add(" : ")
    of tkDot: result.add(".")
    of tkAssign: result.add(" = ")
    of tkComma: result.add(", ")
    of tkRange: result.add("..")
    of tkPlus: result.add(" + ")
    of tkMinus: result.add(" - ")
    of tkMultiply: result.add(" * ")
    of tkDivide: result.add(" / ")
    of tkModulo: result.add(" % ")
    of tkEqual: result.add(" == ")
    of tkNotEqual: result.add(" != ")
    of tkGreater: result.add(" > ")
    of tkLess: result.add(" < ")
    of tkGreaterEqual: result.add(" >= ")
    of tkLessEqual: result.add(" <= ")
    of tkAnd: result.add(" and ")
    of tkOr: result.add(" or ")
    of tkIf, tkElse, tkElsif, tkUnless, tkCase, tkWhen, tkFor, tkIn,
       tkEndif, tkEndunless, tkEndcase, tkEndfor, tkRaw, tkEndraw:
      result.add(($token.kind).toLowerAscii()[2..^1] & " ")
    of tkEOF: discard  # Don't add anything for EOF

proc normalizeWhitespace(s: string): string =
  result = s.strip().replace(re"\s+", " ")

proc compareTemplates(original, reconstructed: string): bool =
  normalizeWhitespace(original) == normalizeWhitespace(reconstructed)

proc runTest(test: TestCase): bool =
  try:
    var lexer = initLexer(test.template_string)
    let tokens = lexer.scanTokens()
    let reconstructed = toTemplate(tokens)
    
    if compareTemplates(test.template_string, reconstructed):
      echo "  [PASS] " & test.name
      return true
    else:
      echo "  [FAIL] " & test.name
      echo "    Original: " & test.template_string
      echo "    Reconstructed: " & reconstructed
      return false
  except Exception as e:
    echo "  [FAIL] " & test.name & " (unexpected error: " & e.msg & ")"
    return false

proc runTestGroup(group: TestGroup): (int, int) =
  echo group.name
  var passed, total: int
  for test in group.tests:
    if runTest(test):
      passed += 1
    total += 1
  (passed, total)

proc main() =
  let jsonContent = readFile("test/golden_liquid.json")
  let jsonNode = parseJson(jsonContent)
  let testGroups = parseTestGroups(jsonNode)

  var totalPassed, totalTests: int

  for group in testGroups:
    let (passed, total) = runTestGroup(group)
    totalPassed += passed
    totalTests += total
  
  echo "\nTotal: " & $totalTests & " tests"
  echo "Passed: " & $totalPassed
  echo "Failed: " & $(totalTests - totalPassed)

  if totalPassed < totalTests:
    quit(QuitFailure)
  else:
    quit(QuitSuccess)

when isMainModule:
  main()
