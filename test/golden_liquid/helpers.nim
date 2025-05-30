import json, unittest, tables, macros, terminal, strutils

import ../../src/liquid/types
import ../../src/liquid/lexer, ../../src/liquid/lexer/[ sections, helpers ]
import ../../src/liquid/parser, ../../src/liquid/parser/[ to_string ]

type
  TestSection* = ref object
    sectionType*: SectionType
    tokens*: seq[Token]
    ast*: Node

export Node, Token, TokenKind, SectionType, Section, Parser, TestSection, unittest, json

proc token*(kind:TokenKind):Token =
  Token(kind: kind, value: "")

proc token*(kind:TokenKind, value:string):Token =
  Token(kind: kind, value: value)


proc nodeString*(strVal: string): Node =
  Node(kind: nkString, strVal: strVal)

proc nodeNumber*(numVal: float): Node =
  Node(kind: nkNumber, numVal: numVal)

proc nodeBoolean*(boolVal: bool): Node =
  Node(kind: nkBoolean, boolVal: boolVal)

proc nodeRange*(rangeStart, rangeEnd: Node): Node =
  Node(kind: nkRange, rangeStart: rangeStart, rangeEnd: rangeEnd)

proc nodeArray*(elements: seq[Node]): Node =
  Node(kind: nkArray, elements: elements)

proc nodeOperator*(op: string, left, right: Node): Node =
  Node(kind: nkOperator, op: op, left: left, right: right)

proc nodeComparison*(op: string, left, right: Node): Node =
  Node(kind: nkComparison, op: op, left: left, right: right)

proc nodeLogical*(op: string, left, right: Node): Node =
  Node(kind: nkLogical, op: op, left: left, right: right)

proc nodeArgument*(argName: string, argValue: Node): Node

proc nodeFilter*(filterName: string, arguments: seq[Node]): Node =
  Node(kind: nkFilter, filterName: filterName, arguments: arguments)

proc nodeFilter*(input: Node, filterName: string, arguments: seq[Node] = @[]): Node =
  var args = @[input]
  for arg in arguments:
    if arg.kind == nkArgument:
      args.add(arg)
    else:
      args.add(nodeArgument("", arg))
  Node(kind: nkFilter, filterName: filterName, arguments: args)

proc nodeEq*(left: Node, right: Node): Node =
  Node(kind: nkComparison, op: "==", left: left, right: right)

proc nodeDot*(base: Node, field: string): Node =
  var segments: seq[Node]
  if base.kind == nkVariable:
    segments = base.segments
  else:
    segments = @[base]
  segments.add(nodeString(field))
  Node(kind: nkVariable, segments: segments)

proc nodeIndex*(base: Node, index: Node): Node =
  var segments: seq[Node]
  if base.kind == nkVariable:
    segments = base.segments
  else:
    segments = @[base]
  segments.add(index)
  Node(kind: nkVariable, segments: segments)

proc nodeArgument*(argName: string, argValue: Node): Node =
  Node(kind: nkArgument, argName: argName, argValue: argValue)

proc nodeVariable*(name: string): Node =
  var segments: seq[Node] = @[]
  var i = 0
  var current = ""

  proc parseSegment() =
    if current.len > 0:
      segments.add(nodeString(current))
      current = ""

  while i < name.len:
    case name[i]
    of '.':
      parseSegment()
      inc(i)
    of '[':
      parseSegment()
      inc(i)
      var j = i
      var bracketContent = ""
      var inQuotes = false
      while j < name.len and (name[j] != ']' or inQuotes):
        if name[j] == '"' or name[j] == '\'':
          inQuotes = not inQuotes
        bracketContent.add(name[j])
        inc(j)
      
      if j < name.len and name[j] == ']':
        bracketContent = bracketContent.strip(chars={'"', '\''})
        var innerNode: Node
        try:
          let num = parseFloat(bracketContent)
          innerNode = nodeNumber(num)
        except ValueError:
          if bracketContent.contains('.') or bracketContent.contains('['):
            innerNode = nodeVariable(bracketContent)
          else:
            innerNode = nodeString(bracketContent)
        
        # Add the index node directly without wrapping
        segments.add(innerNode)
        i = j + 1
      else:
        current.add(name[i])
        inc(i)
    else:
      current.add(name[i])
      inc(i)

  parseSegment()
  result = Node(kind: nkVariable)
  result.segments = segments

proc nodeIdentifier*(name: string): Node =
  nodeVariable(name)

proc nodeLiteral*(value: string): Node =
  nodeString(value)

proc nodeLiteral*(value: int): Node =
  nodeNumber(value.float)

proc nodeLiteral*(value: float): Node =
  nodeNumber(value)

proc nodeLiteral*(value: bool): Node =
  nodeBoolean(value)

proc nodeOutput*(children: seq[Node]): Node =
  Node(kind: nkOutput, children: children)

proc nodeIf*(condition: Node): Node =
  Node(kind: nkTag, tagName: "if", parameters: @[condition])

proc nodeFor*(iterVar: string, collection: Node, parameters: seq[Node] = @[]): Node =
  Node(kind: nkTag, tagName: "for", parameters: @[nodeVariable(iterVar), collection] & parameters)
proc nodeElsIf*(condition: Node): Node =
  Node(kind: nkTag, tagName: "else if", parameters: @[condition])
proc nodeElsUnless*(condition: Node): Node =
  Node(kind: nkTag, tagName: "else unless", parameters: @[condition])

proc nodeUnless*(condition: Node): Node =
  Node(kind: nkTag, tagName: "unless", parameters: @[condition])
proc nodeElse*(): Node =
  Node(kind: nkTag, tagName: "else", parameters: @[])
proc nodeEndIf*(): Node =
  Node(kind: nkEnd, tagName: "if", parameters: @[])


proc nodeCase*(condition: Node): Node =
  Node(kind: nkTag, tagName: "case", parameters: @[condition])
proc nodeCase*(identifier: string): Node =
  Node(kind: nkTag, tagName: "case", parameters: @[nodeVariable(identifier)])
proc nodeWhen*(condition: Node): Node =
  Node(kind: nkTag, tagName: "when", parameters: @[condition])
proc nodeWhen*(conditions: seq[Node]): Node =
  Node(kind: nkTag, tagName: "when", parameters: conditions)
proc nodeEndCase*(): Node =
  Node(kind: nkEnd, tagName: "case", parameters: @[])

proc nodeEndFor*(): Node =
  Node(kind: nkEnd, tagName: "for", parameters: @[])

proc nodeTablerow*(iterVar: string, collection: Node, parameters: seq[Node] = @[]): Node =
  Node(kind: nkTag, tagName: "tablerow", parameters: @[nodeVariable(iterVar), collection] & parameters)


proc nodeCapture*(name: string): Node =
  Node(kind: nkTag, tagName: "capture", parameters: @[nodeVariable(name)])
proc nodeEndCapture*(): Node =
  Node(kind: nkEnd, tagName: "capture", parameters: @[])

proc nodeAssign*(variable: string, value: Node): Node =
  Node(kind: nkTag, tagName: "assign", parameters: @[nodeVariable(variable), value])

proc nodeIncrement*(variable: string, value: Node): Node =
  Node(kind: nkTag, tagName: "increment", parameters: @[nodeVariable(variable), value])

proc nodeDecrement*(variable: string, value: Node): Node =
  Node(kind: nkTag, tagName: "decrement", parameters: @[nodeVariable(variable), value])
proc nodeBreak*(): Node =
  Node(kind: nkTag, tagName: "break", parameters: @[])

proc nodeCycle*(groupName: string, values: seq[Node]): Node =
  Node(kind: nkTag, tagName: "cycle", parameters: @[nodeVariable(groupName), nodeArray(values)])
proc nodeCycle*(values: seq[Node]): Node =
  nodeCycle("cycle", values)

proc nodeComment*(): Node =
  Node(kind: nkTag, tagName: "comment", parameters: @[])

proc nodeEndComment*(): Node =
  Node(kind: nkEnd, tagName: "comment", parameters: @[])

proc nodeDecrement*(variable: string): Node =
  Node(kind: nkTag, tagName: "decrement", parameters: @[nodeVariable(variable)])
proc nodeIncrement*(variable: string): Node =
  Node(kind: nkTag, tagName: "increment", parameters: @[nodeVariable(variable)])

proc nodeEmpty*(): Node =
  Node(kind: nkEmpty)
proc nodeNil*(): Node =
  Node(kind: nkNil)

proc nodeContinue*(): Node =
  Node(kind: nkContinue)

proc nodeIfchanged*(expr: Node = nil): Node =
  if expr.isNil:
    Node(kind: nkTag, tagName: "ifchanged", parameters: @[])
  else:
    Node(kind: nkTag, tagName: "ifchanged", parameters: @[expr])

proc nodeEndIfchanged*(): Node =
  Node(kind: nkEnd, tagName: "ifchanged", parameters: @[])

proc nodeRaw*(content: string): Node =
  Node(kind: nkTag, tagName: "raw", parameters: @[nodeString(content)])
proc nodeEndRaw*(): Node =
   Node(kind: nkEnd, tagName: "raw", parameters: @[])

proc nodeRender*(templateName: string, params: seq[(string, Node)] = @[]): Node =
  var parameters = @[nodeString(templateName)]
  for (name, value) in params:
    parameters.add(nodeVariable(name))
    parameters.add(value)
  Node(kind: nkTag, tagName: "render", parameters: parameters)

proc nodeRender*(templateName: string, boundVar: Node, alias: string = ""): Node =
  var parameters = @[nodeString(templateName), boundVar]
  if alias != "":
    parameters.add(nodeString(alias))
  Node(kind: nkTag, tagName: "render", parameters: parameters)

proc nodeRenderFor*(templateName: string, collection: Node): Node =
  Node(kind: nkTag, tagName: "render", parameters: @[nodeString(templateName), collection])

proc nodeLiquid*(commands: seq[Node]): Node =
  Node(kind: nkTag, tagName: "liquid", parameters: commands)

# proc nodeUnless*(condition: Node, trueBody: seq[Section] = @[], falseBody: seq[Section] = @[], elsifs: seq[(Node, seq[Section])] = @[]): Node =
#   var params = @[condition]
#   # Add body sections as nodes
#   for section in trueBody:
#     if section.ast != nil:
#       params.add(section.ast)
#   for section in falseBody:
#     if section.ast != nil:
#       params.add(section.ast)
#   for (cond, sections) in elsifs:
#     params.add(cond)
#     for section in sections:
#       if section.ast != nil:
#         params.add(section.ast)
#   Node(kind: nkTag, tagName: "unless", parameters: params)

# Complex overload commented out - tests use simpler version
# proc nodeTablerow*(iterVar: string, collection: Node, body: seq[Section], cols: int = 0, limit: int = 0, offset: int = 0): Node =
#   var params = @[nodeVariable(iterVar), collection]
#   if cols > 0:
#     params.add(nodeNumber(cols.float))
#   if limit > 0:
#     params.add(nodeNumber(limit.float))
#   if offset > 0:
#     params.add(nodeNumber(offset.float))
#   for section in body:
#     if section.ast != nil:
#       params.add(section.ast)
#   Node(kind: nkTag, tagName: "tablerow", parameters: params)

# proc nodeTablerow*(iterVar: string, collection: Node, body: seq[Section], cols: Node): Node =
#   var params = @[nodeVariable(iterVar), collection, cols]
#   for section in body:
#     if section.ast != nil:
#       params.add(section.ast)
#   Node(kind: nkTag, tagName: "tablerow", parameters: params)

proc nodeEndTablerow*(): Node =
  Node(kind: nkEnd, tagName: "tablerow", parameters: @[])

proc nodeEcho*(output: seq[Node]): Node =
  Node(kind: nkTag, tagName: "echo", parameters: output)

# proc nodeIf*(condition: Node, body: seq[Section], elseBody: seq[Section] = @[], elsifs: seq[(Node, seq[Section])] = @[]): Node =
#   var params = @[condition]
#   # Add body sections as nodes
#   for section in body:
#     if section.ast != nil:
#       params.add(section.ast)
#   for section in elseBody:
#     if section.ast != nil:
#       params.add(section.ast)
#   for (cond, sections) in elsifs:
#     params.add(cond)
#     for section in sections:
#       if section.ast != nil:
#         params.add(section.ast)
#   Node(kind: nkTag, tagName: "if", parameters: params)

# proc nodeFor*(iterVar: string, collection: Node, body: seq[Section]): Node =
#   var params = @[nodeVariable(iterVar), collection]
#   for section in body:
#     if section.ast != nil:
#       params.add(section.ast)
#   Node(kind: nkTag, tagName: "for", parameters: params)

proc nodeEndUnless*(): Node =
  Node(kind: nkEnd, tagName: "unless", parameters: @[])


proc section*(sectionType:SectionType, tokens:seq[Token], ast:Node):TestSection =
  TestSection(sectionType: sectionType, tokens: tokens, ast: ast)

proc testNode*(actual: Node, expected: Node) =
  if actual.isNil or expected.isNil:
    assert actual.isNil == expected.isNil
    return

  assert actual.kind == expected.kind
  case actual.kind
  of nkTag, nkEnd:
    assert actual.tagName == expected.tagName
    assert actual.parameters.len == expected.parameters.len
    for i in 0..<actual.parameters.len:
      testNode(actual.parameters[i], expected.parameters[i])
  of nkOutput:
    assert actual.children.len == expected.children.len
    for i in 0..<actual.children.len:
      testNode(actual.children[i], expected.children[i])
  of nkVariable:
    assert actual.segments.len == expected.segments.len
    for i in 0..<actual.segments.len:
      testNode(actual.segments[i], expected.segments[i])
  of nkString:
    assert actual.strVal == expected.strVal
  of nkNumber:
    assert actual.numVal == expected.numVal
  of nkBoolean:
    assert actual.boolVal == expected.boolVal
  of nkRange:
    testNode(actual.rangeStart, expected.rangeStart)
    testNode(actual.rangeEnd, expected.rangeEnd)
  of nkArray:
    assert actual.elements.len == expected.elements.len
    for i in 0..<actual.elements.len:
      testNode(actual.elements[i], expected.elements[i])
  of nkOperator, nkComparison, nkLogical:
    assert actual.op == expected.op
    testNode(actual.left, expected.left)
    testNode(actual.right, expected.right)
  of nkFilter:
    assert actual.filterName == expected.filterName
    assert actual.arguments.len == expected.arguments.len
    for i in 0..<actual.arguments.len:
      testNode(actual.arguments[i], expected.arguments[i])
  of nkArgument:
    assert actual.argName == expected.argName
    testNode(actual.argValue, expected.argValue)
  else:
    discard



type
  TestFailure* = ref object
    suiteName*: string
    testName*: string
  CustomFormatter = ref object of OutputFormatter
    failures: seq[TestFailure]
    successes: int
    suiteName: string

let
  formatter* = CustomFormatter(failures: @[])

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



macro verify_result(conditions: untyped): untyped =
  result = newStmtList()
  for condition in conditions:
    let errorMsg = newLit("Assertion failed: " & condition.repr)
    result.add quote do:
      try:
        assert `condition`
      except AssertionDefect:
        styledEcho styleBright, fgYellow, "  [ABORT] ", resetStyle, `errorMsg`
        raise

proc testCase*(
  name: string,
  liquidTemplate: string,
  expected: seq[TestSection],
  context: JsonNode = newJObject(),
  output: string = "",
  partials: Table[string, string] = initTable[string, string](),
  error: bool = false,
  strict: bool = false
) =

  template verify_execution(phase: string, body: untyped) =
    if error:
      body
    else:
      try:
        body
      except CatchableError as e:
        styledEcho styleBright, fgYellow, "  [ABORT] ", resetStyle, phase, " failed with: ", e.msg
        for line in getStackTrace().split("\n"):
          echo "  ", line
        raise

  var
    actual: seq[Section]

  proc testCode() =
    verify_execution "Lexing sections":
      actual = lexSections(liquidTemplate)
      
    verify_result:
      actual.len == expected.len
  
    for i in 0..<actual.len:
      verify_result:
        actual[i].sectionType == expected[i].sectionType
    
    checkpoint "setup"
    
    verify_execution "Lexing":
      actual = lex(liquidTemplate)

    verify_result:
      actual.len == expected.len

    for i in 0..<actual.len:
      #echo "Actual tokens:" & $actual[i].tokens
      verify_result:
        actual[i].tokens.len == expected[i].tokens.len
      for j in 0..<actual[i].tokens.len:
        echo $expected[i].tokens[j] & " -> " & $actual[i].tokens[j]
        verify_result:
          actual[i].tokens[j].kind == expected[i].tokens[j].kind
        if expected[i].tokens[j].value != "":
          verify_result:
            actual[i].tokens[j].value == expected[i].tokens[j].value

    checkpoint "lexer"

    verify_execution "Parsing":
      actual = parse(actual, strict)

    verify_result:
      actual.len == expected.len
    for i in 0..<actual.len:
      try:
        testNode(actual[i].ast, expected[i].ast)
      except AssertionDefect:
        if not error:
          styledEcho styleBright, fgYellow, "  [ABORT]", resetStyle, " AST mismatch"
          echo "Actual AST:"
          echo $actual[i].ast
          echo "\nExpected AST:"
          echo $expected[i].ast
          raise

    checkpoint "parser"
  
  if error:
    test name:
      expect CatchableError:
        testCode()
  else:
    test name:
      testCode()
