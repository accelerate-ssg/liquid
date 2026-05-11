import json, unittest, tables, terminal

import ../src/liquid/compiler/[types, context_functions]
import ../src/liquid/[types, lexer, compiler, vm]

type
  TestSection* = ref object
    sectionKind*: SectionKind
    tokens*: seq[Token]
    ast*: Node

  TestFailure* = ref object
    suiteName*: string
    testName*: string
  CustomFormatter = ref object of OutputFormatter
    failures: seq[TestFailure]
    successes: int
    suiteName: string

let
  formatter* = CustomFormatter(failures: @[])

export Node, Token, TokenKind, SectionKind, Section, Parser, TestSection, unittest, json

method testEnded*(formatter: CustomFormatter, testResult: TestResult) =
  if testResult.status == TestStatus.FAILED:
    formatter.failures.add(TestFailure( suiteName: formatter.suiteName, testName: testResult.testName ))
  elif testResult.status == TestStatus.OK:
    formatter.successes.inc()

  var color = case testResult.status
    of TestStatus.OK: fgGreen
    of TestStatus.FAILED: fgRed
    of TestStatus.SKIPPED: fgYellow
  styledEcho styleBright, color, "  [", $testResult.status, "] ",
      resetStyle, testResult.testName

method suiteEnded*(formatter: CustomFormatter) =
  formatter.suiteName = ""

method failureOccurred*(formatter: CustomFormatter, checkpoints: seq[string], stackTrace: string) =
  discard

method testStarted*(formatter: CustomFormatter, testName: string) =
  discard

method suiteStarted*(formatter: CustomFormatter, suiteName: string) =
  formatter.suiteName = suiteName
  styledEcho styleBright, fgBlue, "\n[Suite] ", resetStyle, suiteName

proc getFailures*(): seq[TestFailure] =
  formatter.failures

proc getSuccesses*(): int =
  formatter.successes

proc renderCase*(
  source: string,
  context: Table[string, VMValue],
  partials: Table[string, string] = initTable[string, string](),
  strict: bool = false
): string =
  let sections = lex(source)
  let compiled = compile(sections, source, strict)
  result = render(compiled.bytecode, compiled.strings, compiled.constants, context, partials)

proc testCase*(
  name: string,
  source: string,
  context: Table[string, VMValue],
  output: string = "",
  partials: Table[string, string] = initTable[string, string](),
  error: bool = false,
  strict: bool = false
) =
  if error:
    test name:
      expect CatchableError:
        discard renderCase(source, context, partials, strict)
  else:
    test name:
      let rendered = renderCase(source, context, partials, strict)
      check rendered == output

proc testCase*(
  name: string,
  source: string,
  context: JsonNode = newJObject(),
  output: string = "",
  partials: Table[string, string] = initTable[string, string](),
  error: bool = false,
  strict: bool = false
) =
  testCase(name, source, context.jsonToContext(), output, partials, error, strict)


proc testCase*(
  name: string,
  source: string,
  expected: seq[TestSection],
  context: JsonNode = newJObject(),
  output: string = "",
  partials: Table[string, string] = initTable[string, string](),
  error: bool = false,
  strict: bool = false
) =
  testCase(name, source, context.jsonToContext(), output, partials, error, strict)
