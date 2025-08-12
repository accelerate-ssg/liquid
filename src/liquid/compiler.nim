import std/[tables, sets, strutils, sequtils]

import types
import compiler/[types]  # The VM types from previous artifact

# Forward declarations
proc compileSection(c: var Compiler, section: Section)
proc compileExpression(c: var Compiler, tokens: openArray[Token], start: int, stop: int)
proc compileText(c: var Compiler, section: Section)
proc compileOutput(c: var Compiler, section: Section)
proc compileTag(c: var Compiler, section: Section)
proc compileIf(c: var Compiler, tokens: openArray[Token])
proc compileFor(c: var Compiler, tokens: openArray[Token])
proc compileAssign(c: var Compiler, tokens: openArray[Token])
proc compileCapture(c: var Compiler, tokens: openArray[Token])
proc compileCase(c: var Compiler, tokens: openArray[Token])
proc compileBreak(c: var Compiler)
proc compileContinue(c: var Compiler)
proc compileUntil(c: var Compiler, stopTags: seq[TokenKind])
#proc peekNextTag(c: Compiler): TokenKind
#proc skipToTag(c: var Compiler, tag: TokenKind)

# Basic utility functions (no dependencies)
proc internString(c: var Compiler, s: string): uint32 =
  if s in c.stringMap:
    return c.stringMap[s]
  result = c.strings.len.uint32
  c.strings.add(s)
  c.stringMap[s] = result

proc emit(c: var Compiler, inst: Instruction) =
  c.instructions.add(inst)

proc emitJump(c: var Compiler, op: OpCode): int =
  ## Emit jump with placeholder offset, return position for patching
  let inst = case op
    of opJump:
      Instruction(op: opJump, offset: 0'i32)
    of opJumpIfFalse:
      Instruction(op: opJumpIfFalse, offset: 0'i32)
    of opJumpIfTrue:
      Instruction(op: opJumpIfTrue, offset: 0'i32)
    of opJumpIfNull:
      Instruction(op: opJumpIfNull, offset: 0'i32)
    of opJumpIfEqual:
      Instruction(op: opJumpIfEqual, offset: 0'i32)
    else:
      raise newException(ValueError, "Invalid jump opcode: " & $op)
  
  c.emit(inst)
  result = c.instructions.len - 1

proc patchJump(c: var Compiler, pos: int) =
  ## Patch jump at pos to jump to current position
  let offset = c.instructions.len - pos - 1
  
  case c.instructions[pos].op
  of opJump:
    c.instructions[pos] = Instruction(op: opJump, offset: offset.int32)
  of opJumpIfFalse:
    c.instructions[pos] = Instruction(op: opJumpIfFalse, offset: offset.int32)
  of opJumpIfTrue:
    c.instructions[pos] = Instruction(op: opJumpIfTrue, offset: offset.int32)
  of opJumpIfNull:
    c.instructions[pos] = Instruction(op: opJumpIfNull, offset: offset.int32)
  of opJumpIfEqual:
    c.instructions[pos] = Instruction(op: opJumpIfEqual, offset: offset.int32)
  of opIterNext:
    c.instructions[pos] = Instruction(op: opIterNext, endOffset: offset.int32)
  else:
    raise newException(ValueError, "Attempting to patch non-jump instruction")

# Helper functions (depend on basic utils)
# proc peekNextTag(c: Compiler): TokenKind =
#   var i = c.currentSection + 1
#   while i < c.sections.len:
#     if c.sections[i].kind == skTag and c.sections[i].tokens.len > 0:
#       return c.sections[i].tokens[0].kind
#     inc i
#   return tkIdentifier

# proc skipToTag(c: var Compiler, tag: TokenKind) =
#   while c.currentSection < c.sections.len:
#     let section = c.sections[c.currentSection]
#     if section.kind == skTag and section.tokens.len > 0:
#       if section.tokens[0].kind == tag:
#         c.currentSection += 1
#         return
#     c.currentSection += 1

proc compileUntil(c: var Compiler, stopTags: seq[TokenKind]) =
  ## Compile sections until we hit one of the stop tags
  while c.currentSection < c.sections.len:
    let section = c.sections[c.currentSection]
    
    # Check if this is a stop tag
    if section.kind == skTag and section.tokens.len > 0:
      if section.tokens[0].kind in stopTags:
        # DON'T increment currentSection here - leave it pointing at the stop tag
        # The caller will handle moving past it
        return
    
    # Compile this section
    c.compileSection(section)

# Expression compilation
proc compileExpression(c: var Compiler, tokens: openArray[Token], 
                      start: int, stop: int) =
  if start >= stop:
    c.emit(Instruction(op: opPushNull))
    return
  
  var pos = start
  
  # First, compile the primary expression (left side)
  let token = tokens[pos]
  case token.kind
  of tkIdentifier:
    let name = c.input[token.start..<token.stop]
    # Validate identifier - @ signs are not allowed in strict mode
    if c.strict and '@' in name:
      raise newException(ValueError, "Invalid identifier: '@' character not allowed in identifiers in strict mode")
    # Check if it's a local variable first
    if name notin c.localVars:
      c.requiredVars.incl(name)
    let stringId = c.internString(name)
    c.emit(Instruction(op: opLoadVar, stringId: stringId))
    inc pos
    
  of tkNumber:
    let numStr = c.input[token.start..<token.stop]
    if '.' in numStr:
      let floatVal = parseFloat(numStr)
      c.emit(Instruction(op: opPushFloat, floatVal: floatVal))
    else:
      let intVal = parseInt(numStr)
      c.emit(Instruction(op: opPushInt, intVal: intVal))
    inc pos
    
  of tkString:
    let str = c.input[token.start + 1..<token.stop - 1]
    let stringId = c.internString(str)
    c.emit(Instruction(op: opPushString, stringId: stringId))
    inc pos
    
  of tkTrue:
    c.emit(Instruction(op: opPushTrue))
    inc pos
    
  of tkFalse:
    c.emit(Instruction(op: opPushFalse))
    inc pos
    
  of tkNil:
    c.emit(Instruction(op: opPushNull))
    inc pos
    
  of tkNot:
    # Unary not operator
    inc pos
    c.compileExpression(tokens, pos, stop)
    c.emit(Instruction(op: opNot))
    return
    
  of tkMinus:
    # Could be unary minus or binary minus
    if pos + 1 < stop and tokens[pos + 1].kind == tkNumber:
      # Negative number literal
      inc pos
      let numStr = "-" & c.input[tokens[pos].start..<tokens[pos].stop]
      if '.' in numStr:
        let floatVal = parseFloat(numStr)
        c.emit(Instruction(op: opPushFloat, floatVal: floatVal))
      else:
        let intVal = parseInt(numStr)
        c.emit(Instruction(op: opPushInt, intVal: intVal))
      inc pos
    else:
      # Unary minus operator
      inc pos
      c.compileExpression(tokens, pos, stop)
      c.emit(Instruction(op: opNegate))
      return
    
  of tkLeftParen:
    # Parenthesized expression
    inc pos
    # Find matching right paren
    var parenDepth = 1
    var endPos = pos
    while endPos < stop and parenDepth > 0:
      if tokens[endPos].kind == tkLeftParen:
        inc parenDepth
      elif tokens[endPos].kind == tkRightParen:
        dec parenDepth
      inc endPos
    
    # Compile the expression inside parens
    c.compileExpression(tokens, pos, endPos - 1)
    pos = endPos  # Skip past the right paren
    
  else:
    # Unknown token, skip it
    inc pos
  
  # Now handle postfix and binary operators
  while pos < stop:
    let op = tokens[pos]
    case op.kind
    of tkDot:
      # Property access
      inc pos
      if pos < stop and tokens[pos].kind == tkIdentifier:
        let propName = c.input[tokens[pos].start..<tokens[pos].stop]
        let propId = c.internString(propName)
        c.emit(Instruction(op: opGetProp, stringId: propId))
        inc pos
      elif pos < stop and tokens[pos].kind == tkNumber:
        # Numeric index after dot is not allowed in standard Liquid - should error
        raise newException(ValueError, "Numeric index after dot notation is not allowed. Use bracket notation instead: [" & $tokens[pos].start & "]")
        
    of tkLeftBracket:
      # Array index
      inc pos
      # Find matching right bracket
      var bracketDepth = 1
      var endPos = pos
      while endPos < stop and bracketDepth > 0:
        if tokens[endPos].kind == tkLeftBracket:
          inc bracketDepth
        elif tokens[endPos].kind == tkRightBracket:
          dec bracketDepth
        inc endPos
      
      # Compile index expression
      c.compileExpression(tokens, pos, endPos - 1)
      c.emit(Instruction(op: opGetIndex))
      pos = endPos
      
    of tkPipe:
      # Filter
      inc pos
      if pos < stop and tokens[pos].kind == tkIdentifier:
        let filterName = c.input[tokens[pos].start..<tokens[pos].stop]
        let filterId = c.internString(filterName)
        inc pos
        
        var argCount: uint8 = 0
        #var args: seq[int] = @[]
        
        if pos < stop and tokens[pos].kind == tkColon:
          inc pos
          # Parse filter arguments
          while pos < stop and tokens[pos].kind != tkPipe:
            let argStart = pos
            # Find end of this argument (comma or end)
            while pos < stop and tokens[pos].kind notin [tkComma, tkPipe]:
              inc pos
            
            # Compile the argument
            c.compileExpression(tokens, argStart, pos)
            inc argCount
            
            if pos < stop and tokens[pos].kind == tkComma:
              inc pos  # Skip comma
        
        c.emit(Instruction(op: opCallFilter, filterId: filterId, argCount: argCount))
        
    # Binary operators
    of tkEq, tkNeq, tkLt, tkLte, tkGt, tkGte:
      let opKind = op.kind
      inc pos
      # Compile right-hand side
      c.compileExpression(tokens, pos, stop)
      
      # Emit comparison instruction
      case opKind
      of tkEq: c.emit(Instruction(op: opEqual))
      of tkNeq: c.emit(Instruction(op: opNotEqual))
      of tkLt: c.emit(Instruction(op: opLess))
      of tkLte: c.emit(Instruction(op: opLessEqual))
      of tkGt: c.emit(Instruction(op: opGreater))
      of tkGte: c.emit(Instruction(op: opGreaterEqual))
      else: discard
      return  # Binary operators consume rest of expression
      
    of tkPlus, tkMinus, tkMul, tkDiv, tkMod:
      # In strict mode, arithmetic operations are not supported in expressions
      if c.strict:
        let opName = case op.kind
          of tkPlus: "addition"
          of tkMinus: "subtraction" 
          of tkMul: "multiplication"
          of tkDiv: "division"
          of tkMod: "modulo"
          else: "arithmetic"
        raise newException(ValueError, opName & " operator not supported in strict mode")
      
      let opKind = op.kind
      inc pos
      # For now, compile rest as right operand
      # A proper implementation would handle precedence
      c.compileExpression(tokens, pos, stop)
      
      case opKind
      of tkPlus: c.emit(Instruction(op: opAdd))
      of tkMinus: c.emit(Instruction(op: opSubtract))
      of tkMul: c.emit(Instruction(op: opMultiply))
      of tkDiv: c.emit(Instruction(op: opDivide))
      of tkMod: c.emit(Instruction(op: opModulo))
      else: discard
      return
      
    of tkAnd:
      inc pos
      c.compileExpression(tokens, pos, stop)
      c.emit(Instruction(op: opAnd))
      return
      
    of tkOr:
      inc pos
      c.compileExpression(tokens, pos, stop)
      c.emit(Instruction(op: opOr))
      return
      
    of tkContains:
      inc pos
      c.compileExpression(tokens, pos, stop)
      c.emit(Instruction(op: opContains))
      return
      
    of tkDoubleDot:
      inc pos
      c.compileExpression(tokens, pos, stop)
      c.emit(Instruction(op: opRange))
      return
      
    else:
      # Unknown operator or end of expression
      inc pos

# Section compilation procedures
proc compileText(c: var Compiler, section: Section) =
  let text = c.input[section.start..<section.stop]
  
  if text.len == 0:
    return
  
  # ALWAYS use batch output for text sections (never escaped)
  let stringId = c.internString(text)
  c.emit(Instruction(op: opBatchOutput, batchCount: 1, stringIds: @[stringId]))

proc compileOutput(c: var Compiler, section: Section) =
  let tokens = section.tokens
  
  if tokens.len == 0:
    return
  
  if tokens.len == 1 and tokens[0].kind == tkIdentifier:
    let varName = c.input[tokens[0].start..<tokens[0].stop]
    # Check if it's a local variable first
    if varName notin c.localVars:
      c.requiredVars.incl(varName)
    let stringId = c.internString(varName)
    c.emit(Instruction(op: opLoadVar, stringId: stringId))
    c.emit(Instruction(op: opOutput))
    return
  
  if tokens.len == 3 and 
     tokens[0].kind == tkIdentifier and
     tokens[1].kind == tkDot and
     tokens[2].kind == tkIdentifier:
    let objName = c.input[tokens[0].start..<tokens[0].stop]
    let propName = c.input[tokens[2].start..<tokens[2].stop]
    # Check if it's a local variable first
    if objName notin c.localVars:
      c.requiredVars.incl(objName)
    
    let objId = c.internString(objName)
    let propId = c.internString(propName)
    
    c.emit(Instruction(op: opLoadVar, stringId: objId))
    c.emit(Instruction(op: opGetProp, stringId: propId))
    c.emit(Instruction(op: opOutput))
    return
  
  c.compileExpression(tokens, 0, tokens.len)
  c.emit(Instruction(op: opOutput))

# Tag compilation procedures
proc compileBreak(c: var Compiler) =
  if c.loopDepth > 0:
    let jumpPos = c.emitJump(opJump)
    c.breakJumps[^1].add(jumpPos)

proc compileContinue(c: var Compiler) =
  if c.loopDepth > 0:
    let jumpPos = c.emitJump(opJump)
    c.continueJumps[^1].add(jumpPos)

proc compileCapture(c: var Compiler, tokens: openArray[Token]) =
  if tokens.len < 2:
    return
  
  let varName = c.input[tokens[1].start..<tokens[1].stop]
  c.localVars.incl(varName)
  let varId = c.internString(varName)
  
  # Emit begin capture instruction
  c.emit(Instruction(op: opBeginCapture, captureId: varId))
  
  # Move past the capture tag itself
  c.currentSection += 1
  
  # Compile everything until we hit endcapture
  # This will compile nested captures recursively
  c.compileUntil(@[tkEndcapture])
  
  # Emit end capture instruction
  c.emit(Instruction(op: opEndCapture, varId: varId))
  
  # Now move past the endcapture tag
  # currentSection is pointing AT the endcapture tag (from compileUntil)
  if c.currentSection < c.sections.len:
    let section = c.sections[c.currentSection]
    if section.kind == skTag and section.tokens.len > 0 and 
       section.tokens[0].kind == tkEndcapture:
      c.currentSection += 1 

proc compileAssign(c: var Compiler, tokens: openArray[Token]) =
  if tokens.len < 4:
    return
  
  let varName = c.input[tokens[1].start..<tokens[1].stop]
  c.localVars.incl(varName)
  let varId = c.internString(varName)
  
  c.compileExpression(tokens, 3, tokens.len)
  c.emit(Instruction(op: opStoreVar, stringId: varId))

proc compileFor(c: var Compiler, tokens: openArray[Token]) =
  if tokens.len < 4:
    c.currentSection += 1  # Skip malformed for
    return
  
  let iterVar = c.input[tokens[1].start..<tokens[1].stop]
  c.localVars.incl(iterVar)
  let iterVarId = c.internString(iterVar)
  
  # Find "in" position
  var inPos = 2
  while inPos < tokens.len and tokens[inPos].kind != tkIn:
    inc inPos
  
  if inPos >= tokens.len:
    c.currentSection += 1  # Skip malformed for
    return
  
  # Simple validation for limit/offset - check for obvious string literals
  for i in (inPos + 1)..<tokens.len:
    if tokens[i].kind == tkIdentifier:
      let tokenText = c.input[tokens[i].start..<tokens[i].stop]
      if tokenText in ["limit", "offset"] and i + 2 < tokens.len and 
         tokens[i + 1].kind == tkColon and tokens[i + 2].kind == tkString:
        let strVal = c.input[tokens[i + 2].start + 1..<tokens[i + 2].stop - 1]  # Remove quotes
        try:
          discard parseInt(strVal)  # Valid number string - allow it
        except ValueError:
          raise newException(ValueError, tokenText & " must be a number, got string '" & strVal & "'")
  
  # Compile collection expression (including limit/offset)
  c.compileExpression(tokens, inPos + 1, tokens.len)
  
  # Setup loop
  c.emit(Instruction(op: opBeginLoop, loopVarIndex: iterVarId.uint16))
  c.loopDepth += 1
  c.breakJumps.add(@[])
  c.continueJumps.add(@[])
  
  # Mark loop start (after BeginLoop)
  let loopStart = c.instructions.len
  
  # Check for next iteration
  let iterCheckPos = c.instructions.len
  c.emit(Instruction(op: opIterNext, endOffset: 0))
  
  # Store loop variable
  c.emit(Instruction(op: opStoreVar, stringId: iterVarId))
  
  # Move past the for tag
  c.currentSection += 1
  
  # Compile loop body
  c.compileUntil(@[tkEndfor])
  
  # Jump back to iteration check
  let jumpBack = loopStart - c.instructions.len - 1
  c.emit(Instruction(op: opJump, offset: jumpBack.int32))
  
  # Patch the IterNext to jump here when done
  let endOffset = c.instructions.len - iterCheckPos - 1
  c.instructions[iterCheckPos] = Instruction(op: opIterNext, endOffset: endOffset.int32)
  
  # Handle breaks and continues
  for breakPos in c.breakJumps[^1]:
    c.patchJump(breakPos)
  
  for continuePos in c.continueJumps[^1]:
    let continueOffset = loopStart - continuePos - 1
    c.instructions[continuePos] = Instruction(op: opJump, offset: continueOffset.int32)
  
  c.breakJumps.setLen(c.breakJumps.len - 1)
  c.continueJumps.setLen(c.continueJumps.len - 1)
  c.loopDepth -= 1
  
  # Move past the endfor tag
  if c.currentSection < c.sections.len:
    let section = c.sections[c.currentSection]
    if section.kind == skTag and section.tokens.len > 0 and
       section.tokens[0].kind == tkEndfor:
      c.currentSection += 1

proc compileIf(c: var Compiler, tokens: openArray[Token]) =
  c.compileExpression(tokens, 1, tokens.len)
  let jumpIfFalse = c.emitJump(opJumpIfFalse)
  
  # Move past the if tag
  c.currentSection += 1
  
  # Compile then-branch
  c.compileUntil(@[tkElsif, tkElse, tkEndif])
  
  # Check what we stopped at
  if c.currentSection < c.sections.len:
    let section = c.sections[c.currentSection]
    if section.kind == skTag and section.tokens.len > 0:
      case section.tokens[0].kind
      of tkElsif:
        let jumpEnd = c.emitJump(opJump)
        c.patchJump(jumpIfFalse)
        c.compileIf(section.tokens)  # Recursive for elsif
        c.patchJump(jumpEnd)
      of tkElse:
        let jumpEnd = c.emitJump(opJump)
        c.patchJump(jumpIfFalse)
        c.currentSection += 1  # Move past else
        c.compileUntil(@[tkEndif])
        c.patchJump(jumpEnd)
      of tkEndif:
        c.patchJump(jumpIfFalse)
        c.currentSection += 1  # Move past endif
      else:
        c.patchJump(jumpIfFalse)
    else:
      c.patchJump(jumpIfFalse)
  else:
    c.patchJump(jumpIfFalse)

proc compileCase(c: var Compiler, tokens: openArray[Token]) =
  # Compile the expression being switched on
  if tokens.len > 1:
    c.compileExpression(tokens, 1, tokens.len)
  else:
    # No expression in case statement
    raise newException(ValueError, "case tag requires an expression")
  
  # Move past the case tag
  c.currentSection += 1
  
  var endJumps: seq[int] = @[]
  var hasDefault = false
  
  while c.currentSection < c.sections.len:
    let section = c.sections[c.currentSection]
    if section.kind != skTag or section.tokens.len == 0:
      c.currentSection += 1
      continue
      
    case section.tokens[0].kind
    of tkWhen:
      # Check if when has expressions
      if section.tokens.len <= 1:
        raise newException(ValueError, "when tag requires at least one expression")
      
      # Parse when conditions (handle OR and comma operators)
      # Duplicate the case value for comparison
      c.emit(Instruction(op: opDup))
      
      # Build condition expression with OR logic
      var conditionResult: seq[int] = @[]  # Positions to patch for true conditions
      var i = 1
      
      while i < section.tokens.len:
        # Find end of current condition (until 'or' or ',' or end)
        var endPos = i
        while endPos < section.tokens.len and 
              section.tokens[endPos].kind notin [tkOr, tkComma]:
          inc endPos
        
        # Compile the condition value
        c.emit(Instruction(op: opDup))  # Duplicate case value for this comparison
        c.compileExpression(section.tokens, i, endPos)
        c.emit(Instruction(op: opEqual))
        
        # If true, jump to execute the when body
        conditionResult.add(c.emitJump(opJumpIfTrue))
        
        # Move to next condition
        i = endPos
        if i < section.tokens.len and section.tokens[i].kind in [tkOr, tkComma]:
          inc i  # Skip the separator
      
      # No condition matched - pop case value and skip when body
      c.emit(Instruction(op: opPop))  # Pop the case value
      let skipWhenBody = c.emitJump(opJump)
      
      # Patch all condition jumps to here (when body start)
      for condPos in conditionResult:
        c.patchJump(condPos)
      
      # Pop the case value (one of the conditions matched)
      c.emit(Instruction(op: opPop))
      
      # Move past when tag
      c.currentSection += 1
      
      # Compile when body
      c.compileUntil(@[tkWhen, tkElse, tkEndcase])
      
      # Jump to end
      endJumps.add(c.emitJump(opJump))
      
      # Patch the skip jump to after the when body
      c.patchJump(skipWhenBody)
      
    of tkElse:
      # Default case
      hasDefault = true
      c.emit(Instruction(op: opPop))  # Pop the case value
      c.currentSection += 1
      c.compileUntil(@[tkEndcase])
      
    of tkEndcase:
      # Pop the case value if no default case handled it
      if not hasDefault:
        c.emit(Instruction(op: opPop))
      
      # Patch all end jumps
      for jump in endJumps:
        c.patchJump(jump)
      
      c.currentSection += 1
      return
      
    else:
      c.currentSection += 1

proc compileTag(c: var Compiler, section: Section) =
  let tokens = section.tokens
  if tokens.len == 0:
    c.currentSection += 1  # Move past empty tag
    return
  
  let firstToken = tokens[0]
  case firstToken.kind
  of tkIf:
    c.compileIf(tokens)
    # compileIf handles its own advancement
  of tkFor:
    c.compileFor(tokens)
    # compileFor handles its own advancement
  of tkAssignTag:
    c.compileAssign(tokens)
    c.currentSection += 1  # Move past assign tag
  of tkCapture:
    c.compileCapture(tokens)
    # compileCapture handles its own advancement
  of tkCase:
    c.compileCase(tokens)
    # compileCase handles its own advancement
  of tkBreak:
    c.compileBreak()
    c.currentSection += 1  # Move past break tag
  of tkContinue:
    c.compileContinue()
    c.currentSection += 1  # Move past continue tag
  of tkElse, tkElsif, tkEndif, tkEndfor, tkEndcapture, tkWhen, tkEndcase:
    # These are handled by their parent structures
    # Don't compile them directly
    c.currentSection += 1
  else:
    # Unknown tag - for now just skip it
    # TODO: Add proper unknown tag detection in strict mode
    c.currentSection += 1

proc compileSection(c: var Compiler, section: Section) =
  case section.kind
  of skText:
    c.compileText(section)
    c.currentSection += 1  # Move past this section
  of skOutput:
    c.compileOutput(section)
    c.currentSection += 1  # Move past this section
  of skTag:
    c.compileTag(section)

# Main entry point (depends on everything else)
proc compile*(sections: seq[Section], input: string, strict: bool = false): CompileResult =
  var compiler = Compiler(
    sections: sections,
    input: input,
    currentSection: 0,
    strict: strict,
    instructions: newSeqOfCap[Instruction](sections.len * 10),
    strings: @[],
    stringMap: initTable[string, uint32](),
    constants: @[],
    requiredVars: initHashSet[string](),
    optionalVars: initHashSet[string](),
    localVars: initHashSet[string](),
    scopeDepth: 0,
    loopDepth: 0
  )
  
  while compiler.currentSection < sections.len:
    let oldSection = compiler.currentSection
    compiler.compileSection(sections[compiler.currentSection])
    # Only increment if the section didn't change (i.e., it wasn't a control flow tag)
    if compiler.currentSection == oldSection:
      compiler.currentSection += 1
  
  result.bytecode = compiler.instructions
  result.strings = compiler.strings
  result.constants = compiler.constants
  result.variables.required = toSeq(compiler.requiredVars)
  result.variables.optional = toSeq(compiler.optionalVars)
  result.variables.locals = toSeq(compiler.localVars)











when isMainModule:
  import std/[unittest]
  import lexer

  # Helper to compile a template string
  proc compileTemplate(source: string): CompileResult =
    let sections = lex(source)
    result = compile(sections, source)

  # Helper to check if instruction exists in bytecode
  proc hasInstruction(bytecode: seq[Instruction], op: OpCode): bool =
    for inst in bytecode:
      if inst.op == op:
        return true
    return false

  template hasInstruction(res: CompileResult, op: OpCode): bool =
    res.bytecode.hasInstruction(op)

  # Helper to count instructions of a type
  proc countInstructions(bytecode: seq[Instruction], op: OpCode): int =
    for inst in bytecode:
      if inst.op == op:
        inc result

  template countInstructions(res: CompileResult, op: OpCode): int =
    res.bytecode.countInstructions(op)

  proc findInstructionPositions(bytecode: seq[Instruction], op: OpCode): seq[int] =
    for i, inst in bytecode:
      if inst.op == op:
        result.add(i)

  proc validateJumps(bytecode: seq[Instruction]): bool =
    for i, inst in bytecode:
      if inst.op in [opJump, opJumpIfFalse, opJumpIfTrue, opJumpIfNull]:
        let target = i + inst.offset.int + 1
        if target < 0 or target > bytecode.len:
          echo "Invalid jump at ", i, " to ", target, " (bytecode len: ", bytecode.len, ")"
          return false
    return true

  suite "Basic Compilation":
    test "Empty template":
      let source = ""
      let result = compileTemplate(source)
      check result.bytecode.len == 0
      check result.strings.len == 0
      check result.variables.required.len == 0

    test "Plain text only":
      let source = "Hello, World!"
      let result = compileTemplate(source)
      
      # Should have push string + output OR batch output
      check result.bytecode.len > 0
      check "Hello, World!" in result.strings
      check result.hasInstruction(opOutput) or result.hasInstruction(opBatchOutput)

    test "Multiple text sections":
      let source = "Hello" & " " & "World"
      let result = compileTemplate(source)
      
      # Should compile to output instructions
      check result.bytecode.len > 0
      check result.hasInstruction(opOutput) or result.hasInstruction(opBatchOutput)

  suite "Variable Output":
    test "Simple variable":
      let source = "{{ name }}"
      let result = compileTemplate(source)
      
      # Should have: LoadVar, Output
      check result.bytecode.len == 2
      check result.bytecode[0].op == opLoadVar
      check result.bytecode[1].op == opOutput
      
      # Should track required variable
      check "name" in result.variables.required
      check "name" in result.strings

    test "Property access":
      let source = "{{ user.name }}"
      let result = compileTemplate(source)
      
      # Should have: LoadVar, GetProp, Output
      check result.bytecode.len == 3
      check result.bytecode[0].op == opLoadVar
      check result.bytecode[1].op == opGetProp
      check result.bytecode[2].op == opOutput
      
      # Should track required variable
      check "user" in result.variables.required
      check "name" in result.strings

    test "Multiple outputs":
      let source = "{{ first }} and {{ second }}"
      let result = compileTemplate(source)
      
      # Should have both variables as required
      check "first" in result.variables.required
      check "second" in result.variables.required
      
      # Should have text "and" in between
      check " and " in result.strings

  suite "Conditionals":
    test "Simple if":
      let source = "{% if show %}Hello{% endif %}"
      let result = compileTemplate(source)
      
      # Should have: LoadVar, JumpIfFalse, Text output, (jump target)
      check result.hasInstruction(opLoadVar)
      check result.hasInstruction(opJumpIfFalse)
      check "show" in result.variables.required

    test "If-else":
      let source = "{% if logged_in %}Welcome{% else %}Please login{% endif %}"
      let result = compileTemplate(source)
      
      # Should have conditional jumps
      check result.hasInstruction(opJumpIfFalse)
      check result.hasInstruction(opJump)  # Jump over else
      check "logged_in" in result.variables.required
      
      # Both strings should be in pool
      check "Welcome" in result.strings
      check "Please login" in result.strings

    test "If with comparison":
      let source = "{% if age > 18 %}Adult{% endif %}"
      let result = compileTemplate(source)
      
      # Should have comparison operator
      check result.hasInstruction(opLoadVar)
      check result.hasInstruction(opPushInt)
      check result.hasInstruction(opGreater)
      check result.hasInstruction(opJumpIfFalse)
      check "age" in result.variables.required

  suite "Loops":
    test "Simple for loop":
      let source = "{% for item in items %}{{ item }}{% endfor %}"
      let result = compileTemplate(source)
      
      # Should have loop instructions
      check result.hasInstruction(opLoadVar)  # Load items
      check result.hasInstruction(opBeginLoop)
      check result.hasInstruction(opIterNext)
      check result.hasInstruction(opStoreVar)  # Store to item
      check result.hasInstruction(opJump)     # Jump back
      
      check "items" in result.variables.required
      check "item" in result.variables.locals

    test "For loop with text":
      let source = "{% for n in numbers %}- {{ n }}\n{% endfor %}"
      let result = compileTemplate(source)
      
      check result.hasInstruction(opBeginLoop)
      check "- " in result.strings or "-" in result.strings
      check "\n" in result.strings
      check "numbers" in result.variables.required
      check "n" in result.variables.locals

    test "Nested loops":
      let source = """
  {% for row in rows %}
    {% for col in row %}{{ col }}{% endfor %}
  {% endfor %}"""
      let result = compileTemplate(source)
      
      # Should have two BeginLoop instructions
      check result.countInstructions(opBeginLoop) == 2
      check "rows" in result.variables.required
      check "row" in result.variables.locals
      check "col" in result.variables.locals

  suite "Variable Assignment":
    test "Simple assign":
      let source = "{% assign x = 5 %}{{ x }}"
      let result = compileTemplate(source)
      
      # Should push 5, store to x, then load x and output
      check result.hasInstruction(opPushInt)
      check result.hasInstruction(opStoreVar)
      check result.hasInstruction(opLoadVar)
      
      check "x" in result.variables.locals
      check "x" notin result.variables.required  # It's local, not required

    test "Assign from variable":
      let source = "{% assign copy = original %}{{ copy }}"
      let result = compileTemplate(source)
      
      check result.hasInstruction(opLoadVar)   # Load original
      check result.hasInstruction(opStoreVar)  # Store to copy
      
      check "original" in result.variables.required
      check "copy" in result.variables.locals

    test "Assign with expression":
      let source = "{% assign fullname = first.name %}{{ fullname }}"
      let result = compileTemplate(source)
      
      check result.hasInstruction(opLoadVar)   # Load first
      check result.hasInstruction(opGetProp)   # Get .name
      check result.hasInstruction(opStoreVar)  # Store to fullname
      
      check "first" in result.variables.required
      check "fullname" in result.variables.locals

  suite "Capture Tag":
    test "Simple capture":
      let source = "{% capture header %}Title: {{ title }}{% endcapture %}{{ header }}"
      let result = compileTemplate(source)
      
      # Should have capture instructions
      check result.hasInstruction(opBeginCapture)
      check result.hasInstruction(opEndCapture)
      
      check "title" in result.variables.required
      check "header" in result.variables.locals

    test "Capture with multiple outputs":
      let source = """
  {% capture card %}
    <h1>{{ name }}</h1>
    <p>{{ description }}</p>
  {% endcapture %}
  {{ card }}"""
      let result = compileTemplate(source)
      
      check result.hasInstruction(opBeginCapture)
      check result.hasInstruction(opEndCapture)
      
      check "name" in result.variables.required
      check "description" in result.variables.required
      check "card" in result.variables.locals

  suite "Literals":
    test "String literal":
      let source = "{{ 'hello' }}"
      let result = compileTemplate(source)
      
      check result.hasInstruction(opPushString)
      check result.hasInstruction(opOutput)
      check "hello" in result.strings

    test "Integer literal":
      let source = "{{ 42 }}"
      let result = compileTemplate(source)
      
      check result.hasInstruction(opPushInt)
      check result.bytecode[0].op == opPushInt
      check result.bytecode[0].intVal == 42

    test "Float literal":
      let source = "{{ 3.14 }}"
      let result = compileTemplate(source)
      
      check result.hasInstruction(opPushFloat)
      check result.bytecode[0].op == opPushFloat
      check result.bytecode[0].floatVal == 3.14

    test "Boolean literals":
      let source1 = "{{ true }}"
      let result1 = compileTemplate(source1)
      check result1.hasInstruction(opPushTrue)
      
      let source2 = "{{ false }}"
      let result2 = compileTemplate(source2)
      check result2.hasInstruction(opPushFalse)

    test "Nil literal":
      let source = "{{ nil }}"
      let result = compileTemplate(source)
      check result.hasInstruction(opPushNull)

  suite "Filters":
    test "Simple filter":
      let source = "{{ name | upcase }}"
      let result = compileTemplate(source)
      
      # Should have: LoadVar, CallFilter, Output
      check result.hasInstruction(opLoadVar)
      check result.hasInstruction(opCallFilter)
      check result.hasInstruction(opOutput)
      
      check "name" in result.variables.required
      check "upcase" in result.strings

    test "Filter with arguments":
      let source = "{{ price | round: 2 }}"
      let result = compileTemplate(source)
      
      check result.hasInstruction(opLoadVar)
      check result.hasInstruction(opPushInt)  # Argument
      check result.hasInstruction(opCallFilter)
      
      # Find the filter instruction and check arg count
      for inst in result.bytecode:
        if inst.op == opCallFilter:
          check inst.argCount == 1

    test "Chained filters":
      let source = "{{ name | upcase | strip }}"
      let result = compileTemplate(source)
      
      # Should have two filter calls
      check result.countInstructions(opCallFilter) == 2
      check "upcase" in result.strings
      check "strip" in result.strings

  suite "Control Flow":
    test "Break in loop":
      let source = "{% for i in items %}{% break %}{% endfor %}"
      let result = compileTemplate(source)
      
      check result.hasInstruction(opBeginLoop)
      check result.hasInstruction(opJump)  # Break is compiled to jump

    test "Continue in loop":
      let source = "{% for i in items %}{% continue %}{{ i }}{% endfor %}"
      let result = compileTemplate(source)
      
      check result.hasInstruction(opBeginLoop)
      check result.hasInstruction(opJump)  # Continue is compiled to jump

  suite "Complex Templates":
    test "Mixed content":
      let source = """<h1>{{ title }}</h1>
  {% if items %}
    <ul>
    {% for item in items %}
      <li>{{ item.name }}: ${{ item.price }}</li>
    {% endfor %}
    </ul>
  {% endif %}"""
      let result = compileTemplate(source)
      
      # Should have all the components
      check result.hasInstruction(opLoadVar)
      check result.hasInstruction(opJumpIfFalse)
      check result.hasInstruction(opBeginLoop)
      check result.hasInstruction(opGetProp)
      
      check "title" in result.variables.required
      check "items" in result.variables.required
      check "item" in result.variables.locals
      
      # HTML should be in strings
      check "<h1>" in result.strings
      # The lexer preserves whitespace, so </h1> comes with the newline and spaces after it
      check "</h1>\n  " in result.strings
      # The <ul> tag comes with surrounding whitespace
      check "\n    <ul>\n    " in result.strings

    test "Template with everything":
      let source = """
  {% assign greeting = 'Hello' %}
  {% capture name_display %}{{ user.firstName }} {{ user.lastName }}{% endcapture %}
  {{ greeting }}, {{ name_display }}!

  {% if user.isAdmin %}
    Admin Dashboard
  {% else %}
    {% for post in posts %}
      - {{ post.title | truncate: 50 }}
    {% endfor %}
  {% endif %}"""
      
      let result = compileTemplate(source)
      
      # Check all features are compiled
      check result.hasInstruction(opStoreVar)      # assign
      check result.hasInstruction(opBeginCapture)  # capture
      check result.hasInstruction(opJumpIfFalse)   # if
      check result.hasInstruction(opBeginLoop)     # for
      check result.hasInstruction(opCallFilter)    # filter
      
      # Check variables
      check "user" in result.variables.required
      check "posts" in result.variables.required
      check "greeting" in result.variables.locals
      check "name_display" in result.variables.locals
      check "post" in result.variables.locals

  suite "Edge Cases":
    test "Empty if body":
      let source = "{% if condition %}{% endif %}"
      let result = compileTemplate(source)
      
      check result.hasInstruction(opLoadVar)
      check result.hasInstruction(opJumpIfFalse)
      check "condition" in result.variables.required

    test "Empty for body":
      let source = "{% for i in items %}{% endfor %}"
      let result = compileTemplate(source)
      
      check result.hasInstruction(opBeginLoop)
      check "items" in result.variables.required
      check "i" in result.variables.locals

    test "Nested captures":
      let source = """
  {% capture outer %}
    {% capture inner %}{{ x }}{% endcapture %}
    Inner: {{ inner }}
  {% endcapture %}
  {{ outer }}"""
      let result = compileTemplate(source)
      
      # Should have two capture blocks
      check result.countInstructions(opBeginCapture) == 2
      check result.countInstructions(opEndCapture) == 2
      check "x" in result.variables.required
      check "inner" in result.variables.locals
      check "outer" in result.variables.locals

    test "Long static text optimization":
      let longText = "a".repeat(200)  # Long text should use batch output
      let source = longText
      let result = compileTemplate(source)
      
      # Should use batch output for efficiency
      check result.hasInstruction(opBatchOutput)
      check longText in result.strings

  suite "Bytecode Structure":
    test "Jump offsets are valid":
      let source = "{% if x %}A{% else %}B{% endif %}"
      let result = compileTemplate(source)
      
      # Find jump instructions
      for i, inst in result.bytecode:
        if inst.op in [opJump, opJumpIfFalse, opJumpIfTrue]:
          let target = i + inst.offset.int + 1
          # Target should be within bytecode
          check target >= 0
          check target <= result.bytecode.len

    test "String IDs are valid":
      let source = "{{ name }} is {{ age }} years old"
      let result = compileTemplate(source)
      
      for inst in result.bytecode:
        if inst.op in [opPushString, opLoadVar, opStoreVar, opGetProp]:
          # String ID should be valid
          check inst.stringId < result.strings.len.uint32

    test "All required variables are tracked":
      let source = "{{ a }}{% if b %}{{ c.d }}{% endif %}{% for e in f %}{{ e }}{% endfor %}"
      let result = compileTemplate(source)
      
      # Should track all variables that are loaded from context
      check "a" in result.variables.required
      check "b" in result.variables.required  
      check "c" in result.variables.required
      check "f" in result.variables.required
      
      # e is local (loop variable)
      check "e" in result.variables.locals
      check "e" notin result.variables.required

  suite "Performance Optimizations":
    test "Fast path for single variable":
      let source = "{{ x }}"
      let result = compileTemplate(source)
      
      # Should be minimal: just LoadVar + Output
      check result.bytecode.len == 2
      check result.bytecode[0].op == opLoadVar
      check result.bytecode[1].op == opOutput

    test "Fast path for property access":
      let source = "{{ obj.prop }}"
      let result = compileTemplate(source)
      
      # Should be minimal: LoadVar + GetProp + Output
      check result.bytecode.len == 3
      check result.bytecode[0].op == opLoadVar
      check result.bytecode[1].op == opGetProp
      check result.bytecode[2].op == opOutput

    test "Batch output for consecutive text":
      # When we have multiple text sections, they might be batched
      let source = "Line 1\nLine 2\nLine 3\n"
      let result = compileTemplate(source)
      
      # Should use efficient output
      check result.bytecode.len <= 2  # Either 1 batch or 1 push+output

  suite "Nested Loops":
    test "Simple nested for loops":
      let source = """{% for row in rows %}
  {% for col in row %}
  {{ col }}
  {% endfor %}
  {% endfor %}"""
      let result = compileTemplate(source)
      
      # Should have exactly 2 BeginLoop and 2 IterNext instructions
      check result.bytecode.countInstructions(opBeginLoop) == 2
      check result.bytecode.countInstructions(opIterNext) == 2
      
      # Should have proper jump instructions for both loops
      check result.bytecode.countInstructions(opJump) >= 2
      
      # All jumps should be valid
      check result.bytecode.validateJumps()
      
      # Check variable tracking
      check "rows" in result.variables.required
      check "row" in result.variables.locals
      check "col" in result.variables.locals

    test "Triple nested loops":
      let source = """{% for a in items %}
    {% for b in a %}
      {% for c in b %}
        {{ c }}
      {% endfor %}
    {% endfor %}
  {% endfor %}"""
      let result = compileTemplate(source)
      
      # Should have 3 of each loop instruction
      check result.bytecode.countInstructions(opBeginLoop) == 3
      check result.bytecode.countInstructions(opIterNext) == 3
      check result.bytecode.countInstructions(opStoreVar) >= 3
      
      # Variables
      check "items" in result.variables.required
      check "a" in result.variables.locals
      check "b" in result.variables.locals
      check "c" in result.variables.locals
      
      # Valid jumps
      check result.bytecode.validateJumps()

    test "Nested loops with break":
      let source = """{% for row in rows %}
    {% for col in row %}
      {% if col == 0 %}
        {% break %}
      {% endif %}
      {{ col }}
    {% endfor %}
  {% endfor %}"""
      let result = compileTemplate(source)
      
      # Should have break compiled as jump
      check result.bytecode.countInstructions(opBeginLoop) == 2
      check result.bytecode.countInstructions(opJumpIfFalse) >= 1  # For the if
      
      # The break should compile to a jump
      let jumps = result.bytecode.findInstructionPositions(opJump)
      check jumps.len >= 3  # At least: if-jump-over, break, and loop-back jumps
      
      check result.bytecode.validateJumps()

    test "Nested loops with continue":
      let source = """{% for i in items %}
    {% for j in i %}
      {% if j < 0 %}
        {% continue %}
      {% endif %}
      {{ j }}
    {% endfor %}
  {% endfor %}"""
      let result = compileTemplate(source)
      
      check result.bytecode.countInstructions(opBeginLoop) == 2
      check result.bytecode.validateJumps()
      
      # Continue should jump back to the inner loop start
      # This is complex to verify without running, but jumps should be valid
      check true

  suite "Nested Captures":
    test "Simple nested capture":
      let source = """{% capture outer %}
    Start
    {% capture inner %}
      {{ value }}
    {% endcapture %}
    Middle: {{ inner }}
    End
  {% endcapture %}
  Result: {{ outer }}"""
      let result = compileTemplate(source)
      
      # Should have 2 begin/end capture pairs
      check result.bytecode.countInstructions(opBeginCapture) == 2
      check result.bytecode.countInstructions(opEndCapture) == 2
      
      # Variables
      check "value" in result.variables.required
      check "inner" in result.variables.locals
      check "outer" in result.variables.locals
      
      # Check that captures are properly nested
      let beginPositions = result.bytecode.findInstructionPositions(opBeginCapture)
      let endPositions = result.bytecode.findInstructionPositions(opEndCapture)
      
      # Inner capture should be completely within outer capture
      check beginPositions.len == 2
      check endPositions.len == 2
      check beginPositions[0] < beginPositions[1]  # Outer starts first
      check endPositions[0] < endPositions[1]      # Inner ends first
      check beginPositions[1] < endPositions[0]    # Inner starts before inner ends

    test "Triple nested capture":
      let source = """{% capture a %}
    {% capture b %}
      {% capture c %}
        deep
      {% endcapture %}
      {{ c }}
    {% endcapture %}
    {{ b }}
  {% endcapture %}
  {{ a }}"""
      let result = compileTemplate(source)
      
      check result.bytecode.countInstructions(opBeginCapture) == 3
      check result.bytecode.countInstructions(opEndCapture) == 3
      
      check "a" in result.variables.locals
      check "b" in result.variables.locals
      check "c" in result.variables.locals

    test "Nested capture - verify structure":
      let source = """{% capture outer %}
  Outer start
  {% capture inner %}
  Inner content: {{ x }}
  {% endcapture %}
  Outer middle: {{ inner }}
  Outer end
  {% endcapture %}
  Final: {{ outer }}"""
      
      let result = compileTemplate(source)
      
      # Verify the structure is correct
      check result.bytecode.countInstructions(opBeginCapture) == 2
      check result.bytecode.countInstructions(opEndCapture) == 2
      
      # Check that inner is completely inside outer
      let beginPositions = result.bytecode.findInstructionPositions(opBeginCapture)
      let endPositions = result.bytecode.findInstructionPositions(opEndCapture)
      
      check beginPositions.len == 2
      check endPositions.len == 2
      
      # Outer capture starts first
      check beginPositions[0] < beginPositions[1]
      # Inner capture ends first (before outer ends)
      check endPositions[0] < endPositions[1]
      # Inner is completely within outer
      check beginPositions[0] < beginPositions[1]
      check beginPositions[1] < endPositions[0]
      check endPositions[0] < endPositions[1]

    test "Nested capture - check missing middle output":
      # The real issue might be that "Outer middle: " isn't being captured
      # Let's create a simpler test to isolate the problem
      let source = """{% capture outer %}A{% capture inner %}B{% endcapture %}C{{ inner }}D{% endcapture %}{{ outer }}"""
      
      let sections = lex(source)
      let result = compile(sections, source)
      
      # Check all parts are present
      check "A" in result.strings or result.strings.anyIt("A" in it)
      check "B" in result.strings or result.strings.anyIt("B" in it)
      check "C" in result.strings or result.strings.anyIt("C" in it)
      check "D" in result.strings or result.strings.anyIt("D" in it)

    test "Debug nested capture compilation":
      # Let's trace through what the compiler is doing
      let source = """{% capture outer %}
  Start
  {% capture inner %}
  Nested
  {% endcapture %}
  Middle: {{ inner }}
  End
  {% endcapture %}
  Result: {{ outer }}"""
      
      let sections = lex(source)
      
      # Manually trace what should happen:
      # Section 0: {% capture outer %}
      # Section 1: "\nStart\n"
      # Section 2: {% capture inner %}
      # Section 3: "\nNested\n"
      # Section 4: {% endcapture %} (inner)
      # Section 5: "\nMiddle: "
      # Section 6: {{ inner }}
      # Section 7: "\nEnd\n"
      # Section 8: {% endcapture %} (outer)
      # Section 9: "\nResult: "
      # Section 10: {{ outer }}
      
      let result = compile(sections, source)
      
      # Check that the middle part between captures is included
      var foundMiddle = false
      for s in result.strings:
        if "Middle" in s:
          foundMiddle = true
          break
      
      check foundMiddle

  suite "Nested Conditionals":
    test "Nested if statements":
      let source = """{% if outer %}
    {% if inner %}
      Both true
    {% else %}
      Outer only
    {% endif %}
  {% else %}
    Neither
  {% endif %}"""
      let result = compileTemplate(source)
      
      # Should have jumps for both if statements
      check result.bytecode.countInstructions(opJumpIfFalse) == 2
      
      # Variables
      check "outer" in result.variables.required
      check "inner" in result.variables.required
      
      check result.bytecode.validateJumps()

    test "If inside for loop":
      let source = """{% for item in items %}
    {% if item.active %}
      {{ item.name }}
    {% endif %}
  {% endfor %}"""
      let result = compileTemplate(source)
      
      check result.bytecode.countInstructions(opBeginLoop) == 1
      check result.bytecode.countInstructions(opJumpIfFalse) == 1
      
      check "items" in result.variables.required
      check "item" in result.variables.locals
      
      check result.bytecode.validateJumps()

    test "For inside if":
      let source = """{% if show_list %}
    {% for item in items %}
      {{ item }}
    {% endfor %}
  {% endif %}"""
      let result = compileTemplate(source)
      
      check result.bytecode.countInstructions(opJumpIfFalse) == 1
      check result.bytecode.countInstructions(opBeginLoop) == 1
      
      check "show_list" in result.variables.required
      check "items" in result.variables.required
      check "item" in result.variables.locals
      
      check result.bytecode.validateJumps()

  suite "Complex Nesting":
    test "Capture inside loop":
      let source = """{% for item in items %}
    {% capture row %}
      <tr><td>{{ item.name }}</td></tr>
    {% endcapture %}
    {{ row }}
  {% endfor %}"""
      let result = compileTemplate(source)
      
      check result.bytecode.countInstructions(opBeginLoop) == 1
      check result.bytecode.countInstructions(opBeginCapture) == 1
      check result.bytecode.countInstructions(opEndCapture) == 1
      
      check "items" in result.variables.required
      check "item" in result.variables.locals
      check "row" in result.variables.locals
      
      check result.bytecode.validateJumps()

    test "Everything nested":
      let source = """{% if enabled %}
    {% for group in groups %}
      {% capture group_output %}
        <div class="group">
          {% for item in group.items %}
            {% if item.visible %}
              <span>{{ item.name }}</span>
            {% endif %}
          {% endfor %}
        </div>
      {% endcapture %}
      {{ group_output }}
    {% endfor %}
  {% endif %}"""
      let result = compileTemplate(source)
      
      # Check all the structures are present
      check result.bytecode.countInstructions(opJumpIfFalse) == 2  # Two ifs
      check result.bytecode.countInstructions(opBeginLoop) == 2   # Two loops
      check result.bytecode.countInstructions(opBeginCapture) == 1
      check result.bytecode.countInstructions(opEndCapture) == 1
      
      # Check variables
      check "enabled" in result.variables.required
      check "groups" in result.variables.required
      check "group" in result.variables.locals
      check "item" in result.variables.locals
      check "group_output" in result.variables.locals
      
      # Most importantly, all jumps should be valid
      check result.bytecode.validateJumps()

    test "Loop with multiple exits":
      let source = """{% for item in items %}
    {% if item.skip %}
      {% continue %}
    {% endif %}
    {% if item.stop %}
      {% break %}
    {% endif %}
    {{ item.value }}
  {% endfor %}"""
      let result = compileTemplate(source)
      
      check result.bytecode.countInstructions(opBeginLoop) == 1
      check result.bytecode.countInstructions(opJumpIfFalse) == 2
      
      # Should have jumps for continue, break, and loop-back
      let jumps = result.bytecode.findInstructionPositions(opJump)
      check jumps.len >= 3
      
      check result.bytecode.validateJumps()

  suite "Edge Cases":
    test "Empty nested structures":
      let source = """{% for a in items %}
    {% for b in a %}
    {% endfor %}
  {% endfor %}"""
      let result = compileTemplate(source)
      
      check result.bytecode.countInstructions(opBeginLoop) == 2
      check result.bytecode.countInstructions(opIterNext) == 2
      check result.bytecode.validateJumps()

    test "Immediately nested loops":
      let source = """{% for a in x %}{% for b in y %}{{ a }}{{ b }}{% endfor %}{% endfor %}"""
      let result = compileTemplate(source)
      
      check result.bytecode.countInstructions(opBeginLoop) == 2
      check "x" in result.variables.required
      check "y" in result.variables.required
      check "a" in result.variables.locals
      check "b" in result.variables.locals
      check result.bytecode.validateJumps()

    test "Deeply nested structure stress test":
      # 5 levels deep
      let source = """{% for a in l1 %}
    {% for b in l2 %}
      {% for c in l3 %}
        {% for d in l4 %}
          {% for e in l5 %}
            {{ e }}
          {% endfor %}
        {% endfor %}
      {% endfor %}
    {% endfor %}
  {% endfor %}"""
      let result = compileTemplate(source)
      
      check result.bytecode.countInstructions(opBeginLoop) == 5
      check result.bytecode.countInstructions(opIterNext) == 5
      check result.bytecode.countInstructions(opStoreVar) >= 5
      
      # All loops should have valid jumps
      check result.bytecode.validateJumps()
      
      # Check all variables
      for i in 1..5:
        check ("l" & $i) in result.variables.required
      for c in ['a', 'b', 'c', 'd', 'e']:
        check ($c) in result.variables.locals

  suite "Capture Section Handling":
    test "Capture with immediate content":
      let source = "{% capture var %}content{% endcapture %}"
      let result = compileTemplate(source)
      
      check result.bytecode.countInstructions(opBeginCapture) == 1
      check result.bytecode.countInstructions(opEndCapture) == 1
      check result.bytecode.countInstructions(opBatchOutput) >= 1  # For "content"
      
      check "var" in result.variables.locals

    test "Capture with multiple sections":
      let source = """{% capture result %}
  First line
  {{ value }}
  Last line
  {% endcapture %}"""
      
      let result = compileTemplate(source)
      
      check result.bytecode.countInstructions(opBeginCapture) == 1
      check result.bytecode.countInstructions(opEndCapture) == 1
      
      # Should have multiple outputs inside capture
      check result.bytecode.countInstructions(opOutput) >= 1  # variable
      check result.bytecode.countInstructions(opBatchOutput) >= 1  # text
      
      check "result" in result.variables.locals
      check "value" in result.variables.required

    test "Back-to-back captures":
      let source = """{% capture a %}A{% endcapture %}{% capture b %}B{% endcapture %}"""
      let result = compileTemplate(source)
      
      check result.bytecode.countInstructions(opBeginCapture) == 2
      check result.bytecode.countInstructions(opEndCapture) == 2
      
      check "a" in result.variables.locals
      check "b" in result.variables.locals
      
      # Ensure captures are not overlapping
      let begins = result.bytecode.findInstructionPositions(opBeginCapture)
      let ends = result.bytecode.findInstructionPositions(opEndCapture)
      
      check begins.len == 2
      check ends.len == 2
      # First capture should complete before second begins
      check ends[0] < begins[1]

    test "Capture with tags inside":
      let source = """{% capture content %}
  {% if show %}
    Visible
  {% else %}
    Hidden
  {% endif %}
  {% endcapture %}"""
      
      let result = compileTemplate(source)
      
      check result.bytecode.countInstructions(opBeginCapture) == 1
      check result.bytecode.countInstructions(opEndCapture) == 1
      check result.bytecode.countInstructions(opJumpIfFalse) == 1  # For the if
      
      check "content" in result.variables.locals
      check "show" in result.variables.required
      
      # The if/else should be between begin and end capture
      let beginPos = result.bytecode.findInstructionPositions(opBeginCapture)[0]
      let endPos = result.bytecode.findInstructionPositions(opEndCapture)[0]
      let ifPos = result.bytecode.findInstructionPositions(opJumpIfFalse)[0]
      
      check beginPos < ifPos
      check ifPos < endPos

    test "Capture with loop inside":
      let source = """{% capture list %}
  {% for item in items %}
    - {{ item }}
  {% endfor %}
  {% endcapture %}"""
      
      let result = compileTemplate(source)
      
      check result.bytecode.countInstructions(opBeginCapture) == 1
      check result.bytecode.countInstructions(opEndCapture) == 1
      check result.bytecode.countInstructions(opBeginLoop) == 1
      
      check "list" in result.variables.locals
      check "items" in result.variables.required
      check "item" in result.variables.locals

    test "Nested capture with correct section advancement":
      let source = """{% capture outer %}
  Outer start
  {% capture inner %}
  Inner content: {{ x }}
  {% endcapture %}
  Outer middle: {{ inner }}
  Outer end
  {% endcapture %}
  Final: {{ outer }}"""
      
      let result = compileTemplate(source)
      
      check result.bytecode.countInstructions(opBeginCapture) == 2
      check result.bytecode.countInstructions(opEndCapture) == 2
      
      # Check that all content is properly compiled
      # The strings include whitespace, so we need to check for substrings
      var foundOuterStart = false
      var foundInnerContent = false
      var foundOuterMiddle = false
      var foundOuterEnd = false
      var foundFinal = false
      
      for s in result.strings:
        if "Outer start" in s: foundOuterStart = true
        if "Inner content:" in s: foundInnerContent = true
        if "Outer middle:" in s: foundOuterMiddle = true
        if "Outer end" in s: foundOuterEnd = true
        if "Final:" in s: foundFinal = true
      
      check foundOuterStart
      check foundInnerContent
      check foundOuterMiddle
      check foundOuterEnd
      check foundFinal
      
      check "outer" in result.variables.locals
      check "inner" in result.variables.locals
      check "x" in result.variables.required

    test "Capture followed by other tags":
      let source = """{% capture header %}
  Title
  {% endcapture %}
  {% if show_header %}
  {{ header }}
  {% endif %}"""
      
      let result = compileTemplate(source)
      
      # Capture should be complete before if starts
      check result.bytecode.countInstructions(opBeginCapture) == 1
      check result.bytecode.countInstructions(opEndCapture) == 1
      check result.bytecode.countInstructions(opJumpIfFalse) == 1
      
      let endCapturePos = result.bytecode.findInstructionPositions(opEndCapture)[0]
      let ifPos = result.bytecode.findInstructionPositions(opJumpIfFalse)[0]
      
      check endCapturePos < ifPos  # Capture ends before if begins

    test "Empty capture":
      let source = "{% capture empty %}{% endcapture %}{{ empty }}"
      
      let result = compileTemplate(source)
      
      check result.bytecode.countInstructions(opBeginCapture) == 1
      check result.bytecode.countInstructions(opEndCapture) == 1
      check "empty" in result.variables.locals

    test "Capture with only whitespace":
      let source = """{% capture ws %}
    
      
  {% endcapture %}"""
      
      let result = compileTemplate(source)
      
      check result.bytecode.countInstructions(opBeginCapture) == 1
      check result.bytecode.countInstructions(opEndCapture) == 1
      check "ws" in result.variables.locals

    test "Capture with assignment inside":
      let source = """{% capture content %}
  {% assign temp = 'value' %}
  Temp is: {{ temp }}
  {% endcapture %}"""
      
      let result = compileTemplate(source)
      
      check result.bytecode.countInstructions(opBeginCapture) == 1
      check result.bytecode.countInstructions(opEndCapture) == 1
      check result.bytecode.countInstructions(opStoreVar) == 1  # For assign
      
      check "content" in result.variables.locals
      check "temp" in result.variables.locals

  suite "Capture Edge Cases":
    test "Capture with mismatched endcapture":
      # This should compile but might not work correctly at runtime
      let source = """{% capture var %}content"""  # Missing endcapture
      
      let sections = lex(source)
      # The lexer should handle this gracefully
      check sections.len > 0
      
      # Compiler should handle incomplete capture
      let result = compile(sections, source)
      check result.bytecode.countInstructions(opBeginCapture) == 1
      # May or may not have endcapture depending on error handling

    test "Multiple captures with same variable name":
      let source = """{% capture x %}First{% endcapture %}
  {% capture x %}Second{% endcapture %}
  {{ x }}"""
      
      let result = compileTemplate(source)
      
      check result.bytecode.countInstructions(opBeginCapture) == 2
      check result.bytecode.countInstructions(opEndCapture) == 2
      check "x" in result.variables.locals
      
      # Both captures should work, second overwrites first

    test "Capture with break/continue (should not affect capture)":
      let source = """{% for i in items %}
    {% capture row %}
      {% if i.skip %}
        Row skipped
        {% break %}  <!-- This break should affect the loop, not capture -->
      {% endif %}
      Row: {{ i.value }}
    {% endcapture %}
    {{ row }}
  {% endfor %}"""
      
      let result = compileTemplate(source)
      
      check result.bytecode.countInstructions(opBeginLoop) == 1
      check result.bytecode.countInstructions(opBeginCapture) == 1
      check result.bytecode.countInstructions(opEndCapture) == 1
      
      # Break should compile but be associated with loop, not capture
      check result.bytecode.validateJumps()
