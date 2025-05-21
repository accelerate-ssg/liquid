import ../types, strutils, sequtils, regex

proc indentRows(str: string): string =
  str.split(re"\n+").mapIt( "  " & it ).join("\n")

proc `$`*(nodes:seq[Node]):string

proc `$`*(node:Node):string =
  if node == nil:
    return "<nil>"

  result = "<" & $node.kind & ">\n"
  case node.kind
  of nkTag:
    result &= indentRows("name: " & $node.tagName)
    result &= "\n  parameters:\n" & indentRows($node.parameters)
  of nkVariable:
    result &= indentRows($node.segments)
  of nkString:
    result = "<" & $node.kind & ": " & $node.strVal & ">\n"
  of nkNumber:
    result = "<" & $node.kind & ": " & $node.numVal & ">\n"
  of nkBoolean:
    result = "<" & $node.kind & ": " & $node.boolVal & ">\n"
  of nkRange:
    result &= indentRows($node.rangeStart & "\n..\n" & $node.rangeEnd)
  of nkArray:
    result &= indentRows($node.elements)
  of nkOperator, nkComparison, nkLogical:
    result &= indentRows($node.left & "\n" & $node.op & "\n" & $node.right)
  of nkFilter:
    result = "<" & $node.kind & ": " & $node.filterName & ">\n"
    result &= indentRows($node.arguments)
  of nkArgument:
    result = "<" & $node.kind & ": " & $node.argName & ">\n"
    result &= indentRows($node.argValue)
  else:
    discard

  
proc `$`*(nodes:seq[Node]):string =
  nodes.mapIt($it).join("\n")
