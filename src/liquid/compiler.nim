import std/[tables, sets, strutils, sequtils]

import types
import compiler/[types]  # The VM types from previous artifact

# Forward declarations
proc compile_section(c: var Compiler, section: Section)
proc compile_expression(c: var Compiler, tokens: openArray[Token], start: int, stop: int)
proc compile_text(c: var Compiler, section: Section)
proc compile_output(c: var Compiler, section: Section)
proc compile_tag(c: var Compiler, section: Section)
proc compile_if(c: var Compiler, tokens: openArray[Token])
proc compile_for(c: var Compiler, tokens: openArray[Token])
proc compile_assign(c: var Compiler, tokens: openArray[Token])
proc compile_capture(c: var Compiler, tokens: openArray[Token])
proc compile_case(c: var Compiler, tokens: openArray[Token])
proc compile_break(c: var Compiler)
proc compile_continue(c: var Compiler)
proc compile_until(c: var Compiler, stop_tags: seq[TokenKind])
proc compile_include(c: var Compiler, tokens: openArray[Token])
proc compile_render(c: var Compiler, tokens: openArray[Token])
proc compile_cycle(c: var Compiler, tokens: openArray[Token])
proc compile_tablerow(c: var Compiler, tokens: openArray[Token])
#proc peekNextTag(c: Compiler): TokenKind
#proc skipToTag(c: var Compiler, tag: TokenKind)

# Basic utility functions (no dependencies)
proc intern_string(c: var Compiler, s: string): uint32 =
  if s in c.stringMap:
    return c.stringMap[s]
  result = c.strings.len.uint32
  c.strings.add(s)
  c.stringMap[s] = result

proc emit(c: var Compiler, inst: Instruction) =
  c.instructions.add(inst)

proc emit_jump(c: var Compiler, op: OpCode): int =
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

proc patch_jump(c: var Compiler, pos: int) =
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

proc compile_until(c: var Compiler, stop_tags: seq[TokenKind]) =
  ## Compile sections until we hit one of the stop tags
  while c.currentSection < c.sections.len:
    let section = c.sections[c.currentSection]
    
    # Check if this is a stop tag
    if section.kind == skTag and section.tokens.len > 0:
      if section.tokens[0].kind in stop_tags:
        # DON'T increment currentSection here - leave it pointing at the stop tag
        # The caller will handle moving past it
        return
    
    # Compile this section
    c.compile_section(section)

# Expression compilation
proc compile_expression(c: var Compiler, tokens: openArray[Token], 
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
    # Validate identifier in strict mode - @ signs are not allowed
    if c.strict and '@' in name:
      raise newException(ValueError, "Invalid identifier: '" & name & "' not allowed in strict mode")
    # Check if it's a local variable first
    if name notin c.localVars:
      c.requiredVars.incl(name)
    let stringId = c.intern_string(name)
    c.emit(Instruction(op: opLoadVar, stringId: stringId))
    inc pos
    
  of tkNumber:
    let num_str = c.input[token.start..<token.stop]
    if '.' in num_str:
      let floatVal = parseFloat(num_str)
      c.emit(Instruction(op: opPushFloat, floatVal: floatVal))
    else:
      let intVal = parseInt(num_str)
      c.emit(Instruction(op: opPushInt, intVal: intVal))
    inc pos
    
  of tkString:
    let str = c.input[token.start + 1..<token.stop - 1]
    let stringId = c.intern_string(str)
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

  of tkEmpty:
    c.emit(Instruction(op: opPushEmpty))
    inc pos

  of tkNot:
    # Unary not operator
    inc pos
    c.compile_expression(tokens, pos, stop)
    c.emit(Instruction(op: opNot))
    return
    
  of tkMinus:
    # Could be unary minus or binary minus
    if pos + 1 < stop and tokens[pos + 1].kind == tkNumber:
      # Negative number literal
      inc pos
      let num_str = "-" & c.input[tokens[pos].start..<tokens[pos].stop]
      if '.' in num_str:
        let floatVal = parseFloat(num_str)
        c.emit(Instruction(op: opPushFloat, floatVal: floatVal))
      else:
        let intVal = parseInt(num_str)
        c.emit(Instruction(op: opPushInt, intVal: intVal))
      inc pos
    else:
      # Unary minus operator
      inc pos
      c.compile_expression(tokens, pos, stop)
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
    c.compile_expression(tokens, pos, endPos - 1)
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
        let prop_name = c.input[tokens[pos].start..<tokens[pos].stop]
        let propId = c.intern_string(prop_name)
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
      c.compile_expression(tokens, pos, endPos - 1)
      c.emit(Instruction(op: opGetIndex))
      pos = endPos
      
    of tkPipe:
      # Filter
      inc pos
      if pos < stop and tokens[pos].kind == tkIdentifier:
        let filter_name = c.input[tokens[pos].start..<tokens[pos].stop]
        let filterId = c.intern_string(filter_name)
        inc pos
        
        var argCount: uint8 = 0

        if pos < stop and tokens[pos].kind == tkColon:
          inc pos
          # Parse filter arguments
          while pos < stop and tokens[pos].kind != tkPipe:
            let arg_start = pos
            # Find end of this argument (comma or end)
            while pos < stop and tokens[pos].kind notin [tkComma, tkPipe]:
              inc pos

            # Check for keyword argument pattern: identifier:value
            # Skip the keyword name and colon, just compile the value
            var expr_start = arg_start
            if pos - arg_start >= 3 and
               tokens[arg_start].kind == tkIdentifier and
               tokens[arg_start + 1].kind == tkColon:
              expr_start = arg_start + 2

            c.compile_expression(tokens, expr_start, pos)
            inc argCount

            if pos < stop and tokens[pos].kind == tkComma:
              inc pos  # Skip comma
        
        c.emit(Instruction(op: opCallFilter, filterId: filterId, argCount: argCount))
        
    # Binary operators
    of tkEq, tkNeq, tkLt, tkLte, tkGt, tkGte:
      let opKind = op.kind
      inc pos
      # Compile right-hand side
      c.compile_expression(tokens, pos, stop)
      
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
      c.compile_expression(tokens, pos, stop)
      
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
      c.compile_expression(tokens, pos, stop)
      c.emit(Instruction(op: opAnd))
      return
      
    of tkOr:
      inc pos
      c.compile_expression(tokens, pos, stop)
      c.emit(Instruction(op: opOr))
      return
      
    of tkContains:
      inc pos
      c.compile_expression(tokens, pos, stop)
      c.emit(Instruction(op: opContains))
      return
      
    of tkDoubleDot:
      inc pos
      c.compile_expression(tokens, pos, stop)
      c.emit(Instruction(op: opRange))
      return
      
    else:
      # Unknown operator or end of expression
      inc pos

# Section compilation procedures
proc compile_text(c: var Compiler, section: Section) =
  let text = c.input[section.start..<section.stop]
  
  if text.len == 0:
    return
  
  # ALWAYS use batch output for text sections (never escaped)
  let stringId = c.intern_string(text)
  c.emit(Instruction(op: opBatchOutput, batchCount: 1, stringIds: @[stringId]))

proc compile_output(c: var Compiler, section: Section) =
  let tokens = section.tokens
  
  if tokens.len == 0:
    return
  
  if tokens.len == 1 and tokens[0].kind == tkIdentifier:
    let var_name = c.input[tokens[0].start..<tokens[0].stop]
    # Validate identifier in strict mode - @ signs are not allowed
    if c.strict and '@' in var_name:
      raise newException(ValueError, "Invalid identifier: '" & var_name & "' not allowed in strict mode")
    # Check if it's a local variable first
    if var_name notin c.localVars:
      c.requiredVars.incl(var_name)
    let stringId = c.intern_string(var_name)
    c.emit(Instruction(op: opLoadVar, stringId: stringId))
    c.emit(Instruction(op: opOutput))
    return

  if tokens.len == 3 and
     tokens[0].kind == tkIdentifier and
     tokens[1].kind == tkDot and
     tokens[2].kind == tkIdentifier:
    let objName = c.input[tokens[0].start..<tokens[0].stop]
    let prop_name = c.input[tokens[2].start..<tokens[2].stop]
    # Validate identifiers in strict mode - @ signs are not allowed
    if c.strict and '@' in objName:
      raise newException(ValueError, "Invalid identifier: '" & objName & "' not allowed in strict mode")
    if c.strict and '@' in prop_name:
      raise newException(ValueError, "Invalid identifier: '" & prop_name & "' not allowed in strict mode")
    # Check if it's a local variable first
    if objName notin c.localVars:
      c.requiredVars.incl(objName)
    
    let objId = c.intern_string(objName)
    let propId = c.intern_string(prop_name)
    
    c.emit(Instruction(op: opLoadVar, stringId: objId))
    c.emit(Instruction(op: opGetProp, stringId: propId))
    c.emit(Instruction(op: opOutput))
    return
  
  c.compile_expression(tokens, 0, tokens.len)
  c.emit(Instruction(op: opOutput))

# Tag compilation procedures
proc compile_break(c: var Compiler) =
  if c.loopDepth > 0:
    let jumpPos = c.emit_jump(opJump)
    c.breakJumps[^1].add(jumpPos)

proc compile_continue(c: var Compiler) =
  if c.loopDepth > 0:
    let jumpPos = c.emit_jump(opJump)
    c.continueJumps[^1].add(jumpPos)

proc compile_capture(c: var Compiler, tokens: openArray[Token]) =
  if tokens.len < 2:
    return

  # Validate that token[1] is a valid capture target (identifier or number)
  if c.strict and tokens[1].kind notin {tkIdentifier, tkNumber}:
    raise newException(ValueError, "Invalid capture target")
  let var_name = c.input[tokens[1].start..<tokens[1].stop]
  c.localVars.incl(var_name)
  let varId = c.intern_string(var_name)
  
  # Emit begin capture instruction
  c.emit(Instruction(op: opBeginCapture, captureId: varId))
  
  # Move past the capture tag itself
  c.currentSection += 1
  
  # Compile everything until we hit endcapture
  # This will compile nested captures recursively
  c.compile_until(@[tkEndcapture])
  
  # Emit end capture instruction
  c.emit(Instruction(op: opEndCapture, varId: varId))
  
  # Now move past the endcapture tag
  # currentSection is pointing AT the endcapture tag (from compile_until)
  if c.currentSection < c.sections.len:
    let section = c.sections[c.currentSection]
    if section.kind == skTag and section.tokens.len > 0 and 
       section.tokens[0].kind == tkEndcapture:
      c.currentSection += 1 

proc compile_assign(c: var Compiler, tokens: openArray[Token]) =
  if tokens.len < 4:
    return

  # Validate that token[1] is a valid assign target (identifier or number)
  if c.strict and tokens[1].kind notin {tkIdentifier, tkNumber}:
    raise newException(ValueError, "Invalid assign target")
  let var_name = c.input[tokens[1].start..<tokens[1].stop]
  # Validate variable name in strict mode
  if c.strict and ('@' in var_name or '?' in var_name):
    raise newException(ValueError, "Invalid variable name: '" & var_name & "' not allowed in strict mode")
  c.localVars.incl(var_name)
  let varId = c.intern_string(var_name)
  
  c.compile_expression(tokens, 3, tokens.len)
  c.emit(Instruction(op: opStoreVar, stringId: varId))

proc compile_include_render(c: var Compiler, tokens: openArray[Token], withContext: bool) =
  # {% include 'name' %}
  # {% include 'name', key: value, ... %}
  # {% include 'name' with var %}
  # {% include 'name' with var as alias %}
  # {% include 'name' for collection %}
  # {% include var_name %}  (include only, variable template name)
  # {% render 'name' %}
  # {% render 'name', key: value, ... %}
  # {% render 'name' with var %}
  # {% render 'name' for collection %}
  if tokens.len < 2:
    return

  var templateNameId: uint32
  var isVarExpr = false
  var pos = 1  # Skip "include"/"render" keyword

  # Get template name
  if tokens[pos].kind == tkString:
    let name = c.input[tokens[pos].start + 1 ..< tokens[pos].stop - 1]  # Strip quotes
    templateNameId = c.intern_string(name)
  else:
    # Variable template name (include only)
    isVarExpr = true
    c.compile_expression(tokens, pos, pos + 1)
    templateNameId = 0  # Not used when isVarExpr=true
  pos += 1

  # Skip optional comma after name
  if pos < tokens.len and tokens[pos].kind == tkComma:
    pos += 1

  # Parse optional modifiers: with, for, keyword args
  var argNames: seq[uint32] = @[]
  var includeWithVar: int32 = -1
  var includeAlias: int32 = -1
  var includeForVar: int32 = -1

  while pos < tokens.len:
    # Handle 'for' keyword (lexed as tkFor, not tkIdentifier)
    if tokens[pos].kind == tkFor:
      # {% include 'name' for collection %}  OR  {% render 'name' for collection %}
      pos += 1
      if pos < tokens.len:
        # Find end of collection expression (until comma or end)
        var exprEnd = pos + 1
        while exprEnd < tokens.len and tokens[exprEnd].kind != tkComma:
          exprEnd += 1
        c.compile_expression(tokens, pos, exprEnd)
        includeForVar = 0  # Marker that 'for' is active (collection value on stack)
        pos = exprEnd
    elif tokens[pos].kind == tkIdentifier:
      let word = c.input[tokens[pos].start ..< tokens[pos].stop]
      case word
      of "with":
        # {% include 'name' with expr %}
        # {% include 'name' with expr as alias %}
        pos += 1
        if pos < tokens.len:
          # Find end of 'with' expression (until 'as', comma, or end)
          var exprEnd = pos
          while exprEnd < tokens.len:
            if tokens[exprEnd].kind == tkComma:
              break
            if tokens[exprEnd].kind == tkIdentifier:
              let w = c.input[tokens[exprEnd].start ..< tokens[exprEnd].stop]
              if w == "as":
                break
            exprEnd += 1
          c.compile_expression(tokens, pos, exprEnd)
          includeWithVar = 0  # Marker that 'with' is active (value is on stack)
          pos = exprEnd
          # Check for 'as' alias
          if pos < tokens.len and tokens[pos].kind == tkIdentifier:
            let maybeAs = c.input[tokens[pos].start ..< tokens[pos].stop]
            if maybeAs == "as":
              pos += 1
              if pos < tokens.len:
                let alias = c.input[tokens[pos].start ..< tokens[pos].stop]
                includeAlias = c.intern_string(alias).int32
                pos += 1
      else:
        # Keyword argument: key: value
        let argName = c.intern_string(word)
        pos += 1
        # Skip colon
        if pos < tokens.len and tokens[pos].kind == tkColon:
          pos += 1
        # Compile value expression (until comma or end)
        var exprEnd = pos
        while exprEnd < tokens.len and tokens[exprEnd].kind != tkComma:
          exprEnd += 1
        if pos < exprEnd:
          c.compile_expression(tokens, pos, exprEnd)
          argNames.add(argName)
        pos = exprEnd
    else:
      # Unrecognized token, skip to avoid infinite loop
      pos += 1
    # Skip commas
    if pos < tokens.len and tokens[pos].kind == tkComma:
      pos += 1

  c.emit(Instruction(op: opInclude,
    templateId: templateNameId,
    withContext: withContext,
    includeArgCount: argNames.len.uint8,
    includeArgNames: argNames,
    includeVarExpr: isVarExpr,
    includeWithVar: includeWithVar,
    includeAlias: includeAlias,
    includeForVar: includeForVar
  ))

proc compile_include(c: var Compiler, tokens: openArray[Token]) =
  c.compile_include_render(tokens, withContext = true)

proc compile_render(c: var Compiler, tokens: openArray[Token]) =
  c.compile_include_render(tokens, withContext = false)

proc compile_for(c: var Compiler, tokens: openArray[Token]) =
  if tokens.len < 4:
    c.currentSection += 1  # Skip malformed for
    return

  let iter_var = c.input[tokens[1].start..<tokens[1].stop]
  c.localVars.incl(iter_var)
  let iter_varId = c.intern_string(iter_var)

  # Find "in" position
  var inPos = 2
  while inPos < tokens.len and tokens[inPos].kind != tkIn:
    inc inPos

  if inPos >= tokens.len:
    c.currentSection += 1  # Skip malformed for
    return

  # Find limit, offset, and reversed positions in the token stream
  var collectionEnd = tokens.len  # End of collection expression
  var limitPos = -1  # Position of "limit" keyword
  var offsetPos = -1  # Position of "offset" keyword
  var isReversed = false

  for i in (inPos + 1)..<tokens.len:
    if tokens[i].kind == tkIdentifier:
      let token_text = c.input[tokens[i].start..<tokens[i].stop]
      if token_text == "limit" and i + 1 < tokens.len and tokens[i + 1].kind == tkColon:
        limitPos = i
        if collectionEnd > i:
          collectionEnd = i
      elif token_text == "offset" and i + 1 < tokens.len and tokens[i + 1].kind == tkColon:
        offsetPos = i
        if collectionEnd > i:
          collectionEnd = i
      elif token_text == "reversed":
        isReversed = true
        if collectionEnd > i:
          collectionEnd = i

  # Validate collection expression starts with a valid token in strict mode
  if c.strict and inPos + 1 < collectionEnd:
    let collToken = tokens[inPos + 1]
    if collToken.kind notin {tkIdentifier, tkLeftParen, tkString, tkNumber, tkTrue, tkFalse, tkNil}:
      raise newException(ValueError, "Invalid for-loop collection expression")

  # Compile collection expression (without limit/offset)
  c.compile_expression(tokens, inPos + 1, collectionEnd)

  # Check for offset: continue special case
  var hasOffsetContinue = false
  if offsetPos >= 0 and offsetPos + 2 < tokens.len and
     tokens[offsetPos + 2].kind == tkContinue:
    hasOffsetContinue = true

  # Compile offset value (if present and not "continue") - pushed on stack first (popped last)
  var hasOffset = false
  if offsetPos >= 0 and not hasOffsetContinue:
    hasOffset = true
    # Find end of offset value (until limit keyword or end of tokens)
    var offsetValueEnd = tokens.len
    if limitPos > offsetPos:
      offsetValueEnd = limitPos
    c.compile_expression(tokens, offsetPos + 2, offsetValueEnd)

  # Compile limit value (if present) - pushed on stack second (popped first)
  var hasLimit = false
  if limitPos >= 0:
    hasLimit = true
    # Find end of limit value (until offset keyword or end of tokens)
    var limitValueEnd = tokens.len
    if offsetPos > limitPos:
      limitValueEnd = offsetPos
    c.compile_expression(tokens, limitPos + 2, limitValueEnd)

  # Build forloop.name: "{var_name}-{collection_source_text}"
  var collectionText = ""
  for i in (inPos + 1)..<collectionEnd:
    collectionText.add(c.input[tokens[i].start..<tokens[i].stop])
    # Add dots between identifier chains
    if i + 1 < collectionEnd and tokens[i].kind == tkIdentifier and
       tokens[i + 1].kind == tkDot:
      discard  # dot will be added by the next token
  let loopName = iter_var & "-" & collectionText
  let loopNameId = c.intern_string(loopName).int32

  # Setup loop
  c.emit(Instruction(op: opBeginLoop, loopVarIndex: iter_varId.uint16,
                     hasLimit: hasLimit, hasOffset: hasOffset,
                     hasOffsetContinue: hasOffsetContinue,
                     isReversed: isReversed, loopNameId: loopNameId))
  c.loopDepth += 1
  c.breakJumps.add(@[])
  c.continueJumps.add(@[])
  
  # Mark loop start (after BeginLoop)
  let loopStart = c.instructions.len
  
  # Check for next iteration
  let iterCheckPos = c.instructions.len
  c.emit(Instruction(op: opIterNext, endOffset: 0))
  
  # Store loop variable
  c.emit(Instruction(op: opStoreVar, stringId: iter_varId))
  
  # Move past the for tag
  c.currentSection += 1

  # Compile loop body (stop at else or endfor)
  c.compile_until(@[tkElse, tkEndfor])

  # Jump back to iteration check
  let jumpBack = loopStart - c.instructions.len - 1
  c.emit(Instruction(op: opJump, offset: jumpBack.int32))

  # After the loop body: this is where opIterNext jumps when iteration ends
  let afterLoop = c.instructions.len

  # Handle breaks and continues
  for breakPos in c.breakJumps[^1]:
    c.patch_jump(breakPos)

  for continuePos in c.continueJumps[^1]:
    let continueOffset = loopStart - continuePos - 1
    c.instructions[continuePos] = Instruction(op: opJump, offset: continueOffset.int32)

  c.breakJumps.setLen(c.breakJumps.len - 1)
  c.continueJumps.setLen(c.continueJumps.len - 1)
  c.loopDepth -= 1

  # Check for {% else %} block (default for empty collections)
  var hasElse = false
  if c.currentSection < c.sections.len:
    let section = c.sections[c.currentSection]
    if section.kind == skTag and section.tokens.len > 0 and
       section.tokens[0].kind == tkElse:
      hasElse = true
      # Jump over else block after normal loop completion
      let jumpOverElse = c.emit_jump(opJump)

      # Else block starts here
      let elseStart = c.instructions.len

      c.currentSection += 1  # Move past else tag
      c.compile_until(@[tkEndfor])

      let afterElse = c.instructions.len
      c.patch_jump(jumpOverElse)

      # Patch iterNext with both offsets:
      # endOffset = past else (after completing iteration)
      # elseOffset = to else content (when collection is empty)
      c.instructions[iterCheckPos] = Instruction(op: opIterNext,
        endOffset: (afterElse - iterCheckPos - 1).int32,
        elseOffset: (elseStart - iterCheckPos - 1).int32)

  if not hasElse:
    # No else block: patch iterNext to jump after loop
    let endOffset = afterLoop - iterCheckPos - 1
    c.instructions[iterCheckPos] = Instruction(op: opIterNext,
      endOffset: endOffset.int32, elseOffset: 0)

  # Move past the endfor tag
  if c.currentSection < c.sections.len:
    let section = c.sections[c.currentSection]
    if section.kind == skTag and section.tokens.len > 0 and
       section.tokens[0].kind == tkEndfor:
      c.currentSection += 1

proc compile_if(c: var Compiler, tokens: openArray[Token]) =
  c.compile_expression(tokens, 1, tokens.len)
  let jumpIfFalse = c.emit_jump(opJumpIfFalse)
  
  # Move past the if tag
  c.currentSection += 1
  
  # Compile then-branch
  c.compile_until(@[tkElsif, tkElse, tkEndif])
  
  # Check what we stopped at
  if c.currentSection < c.sections.len:
    let section = c.sections[c.currentSection]
    if section.kind == skTag and section.tokens.len > 0:
      case section.tokens[0].kind
      of tkElsif:
        let jumpEnd = c.emit_jump(opJump)
        c.patch_jump(jumpIfFalse)
        c.compile_if(section.tokens)  # Recursive for elsif
        c.patch_jump(jumpEnd)
      of tkElse:
        let jumpEnd = c.emit_jump(opJump)
        c.patch_jump(jumpIfFalse)
        c.currentSection += 1  # Move past else
        c.compile_until(@[tkEndif])
        c.patch_jump(jumpEnd)
      of tkEndif:
        c.patch_jump(jumpIfFalse)
        c.currentSection += 1  # Move past endif
      else:
        c.patch_jump(jumpIfFalse)
    else:
      c.patch_jump(jumpIfFalse)
  else:
    c.patch_jump(jumpIfFalse)

proc compile_increment(c: var Compiler, tokens: openArray[Token]) =
  # {% increment var %} - output current value (default 0), then increment
  if tokens.len < 2:
    return
  let var_name = c.input[tokens[1].start..<tokens[1].stop]
  # Load variable (defaults to null), coerce null to 0, output, add 1, store
  let varId = c.intern_string(var_name)
  c.emit(Instruction(op: opLoadVar, stringId: varId))
  c.emit(Instruction(op: opPushInt, intVal: 0))
  c.emit(Instruction(op: opAdd))  # null + 0 = 0, n + 0 = n
  c.emit(Instruction(op: opDup))
  c.emit(Instruction(op: opOutput))
  c.emit(Instruction(op: opPushInt, intVal: 1))
  c.emit(Instruction(op: opAdd))
  c.emit(Instruction(op: opStoreVar, stringId: varId))

proc compile_decrement(c: var Compiler, tokens: openArray[Token]) =
  # {% decrement var %} - decrement, then output (starts at -1)
  if tokens.len < 2:
    return
  let var_name = c.input[tokens[1].start..<tokens[1].stop]
  # Load variable (defaults to null/0), subtract 1, store, output
  let varId = c.intern_string(var_name)
  c.emit(Instruction(op: opLoadVar, stringId: varId))
  c.emit(Instruction(op: opPushInt, intVal: 1))
  c.emit(Instruction(op: opSubtract))
  c.emit(Instruction(op: opDup))
  c.emit(Instruction(op: opStoreVar, stringId: varId))
  c.emit(Instruction(op: opOutput))

proc compile_cycle(c: var Compiler, tokens: openArray[Token]) =
  # {% cycle [name:] val1, val2, ... %}
  # Cycle through values, outputting the next one each time
  if tokens.len < 2:
    return

  var pos = 1  # Skip "cycle" keyword
  var group_id: int32 = -1
  var group_is_var = false

  # Check for named cycle: name: val1, val2, ...
  # Named cycle has pattern: (identifier|string) colon ...
  # Need to look ahead to see if there's a colon after first token
  if tokens.len >= 3 and tokens[pos + 1].kind == tkColon:
    # Named cycle
    let name_token = tokens[pos]
    if name_token.kind == tkString:
      let name = c.input[(name_token.start + 1)..<(name_token.stop - 1)]  # Strip quotes
      group_id = c.intern_string(name).int32
      group_is_var = false
    elif name_token.kind == tkIdentifier:
      # Variable name — resolved at runtime
      let name = c.input[name_token.start..<name_token.stop]
      group_id = c.intern_string(name).int32
      group_is_var = true
    pos += 2  # Skip name and colon

  # Parse cycle values (comma-separated expressions)
  var arg_count: uint8 = 0
  var key_parts: seq[string] = @[]  # For building unnamed cycle key

  while pos < tokens.len:
    # Parse one value
    let expr_start = pos
    # Find end of this expression (next comma or end)
    var expr_end = pos
    while expr_end < tokens.len and tokens[expr_end].kind != tkComma:
      expr_end += 1

    if expr_end > expr_start:
      c.compile_expression(tokens, expr_start, expr_end)
      arg_count += 1
      # Build key part from source text for unnamed cycles
      if group_id == -1:
        key_parts.add(c.input[tokens[expr_start].start..<tokens[expr_end - 1].stop])

    pos = expr_end
    if pos < tokens.len and tokens[pos].kind == tkComma:
      pos += 1  # Skip comma

  # For unnamed cycles, build a key from the argument source text
  var cycle_key: uint32 = 0
  if group_id == -1:
    cycle_key = c.intern_string(key_parts.join(","))

  c.emit(Instruction(op: opCycle,
    cycleGroupId: group_id,
    cycleGroupIsVar: group_is_var,
    cycleArgCount: arg_count,
    cycleKey: cycle_key))

proc compile_tablerow(c: var Compiler, tokens: openArray[Token]) =
  # {% tablerow var in collection [cols:N] [limit:N] [offset:N] %}...{% endtablerow %}
  if tokens.len < 4:
    c.currentSection += 1
    return

  let iter_var = c.input[tokens[1].start..<tokens[1].stop]
  c.localVars.incl(iter_var)
  let iter_varId = c.intern_string(iter_var)

  # Find "in" position
  var inPos = 2
  while inPos < tokens.len and tokens[inPos].kind != tkIn:
    inc inPos
  if inPos >= tokens.len:
    c.currentSection += 1
    return

  # Find cols, limit, offset positions
  var collectionEnd = tokens.len
  var colsPos = -1
  var limitPos = -1
  var offsetPos = -1

  for i in (inPos + 1)..<tokens.len:
    if tokens[i].kind == tkIdentifier:
      let token_text = c.input[tokens[i].start..<tokens[i].stop]
      if token_text == "cols" and i + 1 < tokens.len and tokens[i + 1].kind == tkColon:
        colsPos = i
        if collectionEnd > i: collectionEnd = i
      elif token_text == "limit" and i + 1 < tokens.len and tokens[i + 1].kind == tkColon:
        limitPos = i
        if collectionEnd > i: collectionEnd = i
      elif token_text == "offset" and i + 1 < tokens.len and tokens[i + 1].kind == tkColon:
        offsetPos = i
        if collectionEnd > i: collectionEnd = i

  # Compile collection expression
  c.compile_expression(tokens, inPos + 1, collectionEnd)

  # Helper to find end of keyword value (next keyword or end)
  proc findValueEnd(tokens: openArray[Token], kwPos: int,
                     colsPos, limitPos, offsetPos: int): int =
    result = tokens.len
    for other in [colsPos, limitPos, offsetPos]:
      if other > kwPos and other < result:
        result = other

  # Compile offset value
  var hasOffset = false
  if offsetPos >= 0:
    hasOffset = true
    let valEnd = findValueEnd(tokens, offsetPos, colsPos, limitPos, offsetPos)
    c.compile_expression(tokens, offsetPos + 2, valEnd)

  # Compile limit value
  var hasLimit = false
  if limitPos >= 0:
    hasLimit = true
    let valEnd = findValueEnd(tokens, limitPos, colsPos, limitPos, offsetPos)
    c.compile_expression(tokens, limitPos + 2, valEnd)

  # Compile cols value
  var hasCols = false
  if colsPos >= 0:
    hasCols = true
    let valEnd = findValueEnd(tokens, colsPos, colsPos, limitPos, offsetPos)
    c.compile_expression(tokens, colsPos + 2, valEnd)

  # Emit tablerow begin
  c.emit(Instruction(op: opTablerowBegin,
    tablerowVarIndex: iter_varId.uint16,
    tablerowHasLimit: hasLimit,
    tablerowHasOffset: hasOffset,
    tablerowHasCols: hasCols))

  # Mark body start position
  let bodyStart = c.instructions.len

  # Move past the tablerow tag
  c.currentSection += 1

  # Compile loop body (until endtablerow)
  c.compile_until(@[tkEndtablerow])

  # Emit tablerow iteration (handles </td>, row wrapping, loops back or ends)
  let iterPos = c.instructions.len
  c.emit(Instruction(op: opTablerowIter,
    tablerowEndOffset: 0,  # Will be patched
    tablerowBodyOffset: (bodyStart - c.instructions.len - 1).int32))

  # After loop
  let afterLoop = c.instructions.len

  # Patch the iter instruction's end offset
  c.instructions[iterPos] = Instruction(op: opTablerowIter,
    tablerowEndOffset: (afterLoop - iterPos - 1).int32,
    tablerowBodyOffset: (bodyStart - iterPos - 1).int32)

  # Move past endtablerow
  if c.currentSection < c.sections.len:
    let section = c.sections[c.currentSection]
    if section.kind == skTag and section.tokens.len > 0 and
       section.tokens[0].kind == tkEndtablerow:
      c.currentSection += 1

proc compile_ifchanged(c: var Compiler, tokens: openArray[Token]) =
  # {% ifchanged %}...{% endifchanged %}
  c.emit(Instruction(op: opBeginIfchanged))

  # Move past the ifchanged tag
  c.currentSection += 1

  # Compile body until endifchanged
  c.compile_until(@[tkEndifchanged])

  c.emit(Instruction(op: opEndIfchanged))

  # Move past endifchanged
  if c.currentSection < c.sections.len:
    let section = c.sections[c.currentSection]
    if section.kind == skTag and section.tokens.len > 0 and
       section.tokens[0].kind == tkEndifchanged:
      c.currentSection += 1

proc compile_unless(c: var Compiler, tokens: openArray[Token]) =
  # Unless is the inverse of if: execute body when condition is FALSE
  c.compile_expression(tokens, 1, tokens.len)
  let jumpIfTrue = c.emit_jump(opJumpIfTrue)  # Skip body if condition is true

  # Move past the unless tag
  c.currentSection += 1

  # Compile body (until else or endunless)
  c.compile_until(@[tkElse, tkEndunless])

  # Check what we stopped at
  if c.currentSection < c.sections.len:
    let section = c.sections[c.currentSection]
    if section.kind == skTag and section.tokens.len > 0:
      case section.tokens[0].kind
      of tkElse:
        let jumpEnd = c.emit_jump(opJump)
        c.patch_jump(jumpIfTrue)
        c.currentSection += 1  # Move past else
        c.compile_until(@[tkEndunless])
        c.patch_jump(jumpEnd)
      of tkEndunless:
        c.patch_jump(jumpIfTrue)
        c.currentSection += 1  # Move past endunless
      else:
        c.patch_jump(jumpIfTrue)
    else:
      c.patch_jump(jumpIfTrue)
  else:
    c.patch_jump(jumpIfTrue)

proc compile_case(c: var Compiler, tokens: openArray[Token]) =
  # Compile the expression being switched on
  if tokens.len > 1:
    c.compile_expression(tokens, 1, tokens.len)
  else:
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
      if section.tokens.len <= 1:
        raise newException(ValueError, "when tag requires at least one expression")

      # Check for 'and' separator — makes the when invalid (Ruby Liquid behavior)
      var hasAnd = false
      for i in 1..<section.tokens.len:
        if section.tokens[i].kind == tkAnd:
          hasAnd = true
          break

      if hasAnd:
        # Skip this when block entirely (advance past body without compiling)
        c.currentSection += 1
        while c.currentSection < c.sections.len:
          let s = c.sections[c.currentSection]
          if s.kind == skTag and s.tokens.len > 0 and
             s.tokens[0].kind in {tkWhen, tkElse, tkEndcase}:
            break
          c.currentSection += 1
      else:
        # Parse when values (comma/or separated)
        # In Ruby Liquid, the body runs once per matching value
        var values: seq[tuple[start, stop: int]] = @[]
        var i = 1
        while i < section.tokens.len:
          var endPos = i
          while endPos < section.tokens.len and
                section.tokens[endPos].kind notin [tkOr, tkComma]:
            inc endPos
          if endPos > i:
            values.add((i, endPos))
          i = endPos
          if i < section.tokens.len and section.tokens[i].kind in [tkOr, tkComma]:
            inc i

        # Save section position for when body
        c.currentSection += 1
        let bodyStartSection = c.currentSection

        # For each value, check and conditionally execute the body
        for vi, val in values:
          # Dup the case value for comparison
          c.emit(Instruction(op: opDup))
          c.compile_expression(section.tokens, val.start, val.stop)
          c.emit(Instruction(op: opEqual))
          let skipBody = c.emit_jump(opJumpIfFalse)

          # Execute body
          c.currentSection = bodyStartSection
          c.compile_until(@[tkWhen, tkElse, tkEndcase])

          c.patch_jump(skipBody)

        # After all value checks, ensure we're past the body
        # (compile_until already positioned us past the body)

    of tkElse:
      hasDefault = true
      c.emit(Instruction(op: opPop))  # Pop the case value
      c.currentSection += 1
      c.compile_until(@[tkEndcase])

    of tkEndcase:
      if not hasDefault:
        c.emit(Instruction(op: opPop))
      for jump in endJumps:
        c.patch_jump(jump)
      c.currentSection += 1
      return

    else:
      c.currentSection += 1

proc compile_tag(c: var Compiler, section: Section) =
  let tokens = section.tokens
  if tokens.len == 0:
    c.currentSection += 1  # Move past empty tag
    return
  
  let firstToken = tokens[0]
  case firstToken.kind
  of tkIf:
    c.compile_if(tokens)
    # compile_if handles its own advancement
  of tkUnless:
    c.compile_unless(tokens)
    # compile_unless handles its own advancement
  of tkFor:
    c.compile_for(tokens)
    # compile_for handles its own advancement
  of tkAssignTag:
    c.compile_assign(tokens)
    c.currentSection += 1  # Move past assign tag
  of tkCapture:
    c.compile_capture(tokens)
    # compile_capture handles its own advancement
  of tkCase:
    c.compile_case(tokens)
    # compile_case handles its own advancement
  of tkBreak:
    c.compile_break()
    c.currentSection += 1  # Move past break tag
  of tkContinue:
    c.compile_continue()
    c.currentSection += 1  # Move past continue tag
  of tkElse, tkElsif, tkEndif, tkEndfor, tkEndcapture, tkWhen, tkEndcase, tkEndunless, tkEndtablerow, tkEndifchanged:
    # These are handled by their parent structures
    # Don't compile them directly
    c.currentSection += 1
  of tkIdentifier:
    # Handle custom tags by name (increment, decrement, etc.)
    let tag_name = c.input[firstToken.start..<firstToken.stop]
    case tag_name
    of "increment":
      c.compile_increment(tokens)
      c.currentSection += 1
    of "decrement":
      c.compile_decrement(tokens)
      c.currentSection += 1
    of "include":
      c.compile_include(tokens)
      c.currentSection += 1
    of "render":
      c.compile_render(tokens)
      c.currentSection += 1
    of "cycle":
      c.compile_cycle(tokens)
      c.currentSection += 1
    of "tablerow":
      c.compile_tablerow(tokens)
    of "ifchanged":
      c.compile_ifchanged(tokens)
    else:
      if c.strict:
        raise newException(ValueError, "Unknown tag: '" & tag_name & "'")
      c.currentSection += 1
  else:
    if c.strict:
      let tag_name = c.input[firstToken.start..<firstToken.stop]
      raise newException(ValueError, "Unknown tag: '" & tag_name & "'")
    c.currentSection += 1

proc compile_section(c: var Compiler, section: Section) =
  case section.kind
  of skText:
    c.compile_text(section)
    c.currentSection += 1  # Move past this section
  of skOutput:
    c.compile_output(section)
    c.currentSection += 1  # Move past this section
  of skTag:
    c.compile_tag(section)

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
    let old_section = compiler.currentSection
    compiler.compile_section(sections[compiler.currentSection])
    # Only increment if the section didn't change (i.e., it wasn't a control flow tag)
    if compiler.currentSection == old_section:
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

  suite "Case/When":
    test "When with and separator":
      # In Ruby Liquid, 'and' in when makes the entire when block invalid (no output)
      let source = "{% case x %}{% when 'a' and 'b', 'c' %}match{% endcase %}"
      let result = compileTemplate(source)

      # Should compile without errors but skip the when body (no dup/equal)
      check not result.hasInstruction(opDup)
      check not result.hasInstruction(opEqual)
      check result.bytecode.validateJumps()

  suite "Strict Mode":
    test "Unknown tag raises in strict mode":
      let source = "{% nosuchthing %}"
      let sections = lex(source)
      expect ValueError:
        discard compile(sections, source, strict = true)

    test "Unknown tag is ignored in non-strict mode":
      let source = "{% nosuchthing %}"
      let sections = lex(source)
      let result = compile(sections, source, strict = false)
      check result.bytecode.len == 0

    test "@ identifier raises in strict mode":
      let source = "{{ @foo }}"
      let sections = lex(source)
      expect ValueError:
        discard compile(sections, source, strict = true)

    test "? in assign raises in strict mode":
      let source = "{% assign foo? = 'hello' %}"
      let sections = lex(source)
      expect ValueError:
        discard compile(sections, source, strict = true)

    test "? in output is allowed in strict mode":
      let source = "{{ foo? }}"
      let sections = lex(source)
      let result = compile(sections, source, strict = true)
      check result.bytecode.len > 0

    test "@ identifier works in non-strict mode":
      let source = "{{ @foo }}"
      let sections = lex(source)
      let result = compile(sections, source, strict = false)
      check result.bytecode.len > 0

    test "Leading hyphen in assign raises in strict mode":
      let source = "{% assign -foo = 'hello' %}"
      let sections = lex(source)
      expect ValueError:
        discard compile(sections, source, strict = true)

    test "Leading hyphen in capture raises in strict mode":
      let source = "{% capture -foo %}hello{% endcapture %}"
      let sections = lex(source)
      expect ValueError:
        discard compile(sections, source, strict = true)

    test "Leading hyphen in for-loop target raises in strict mode":
      let source = "{% for x in -foo %}{{ x }}{% endfor %}"
      let sections = lex(source)
      expect ValueError:
        discard compile(sections, source, strict = true)
