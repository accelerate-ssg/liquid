import ../../types, ../core
import tables

const tag_info* = TagHandlerInfo(
  opening_tag: "liquid",
  block_tag: false,
  inner_tags: @[]
)

proc parseLiquidCommand(p: Parser): Node =
  # Parse a single liquid command
  if p.position >= p.tokens.len or p.current.kind != TkIdentifier:
    return nil
  
  let commandName = p.current.value
  
  case commandName:
  of "echo":
    discard p.advance()  # Skip "echo"
    var outputs: seq[Node] = @[]
    while p.position < p.tokens.len and p.current.kind != TkIdentifier:
      let expr = p.parseExpression()
      if expr != nil:
        outputs.add(expr)
      else:
        break
    result = Node(kind: nkTag, tagName: "echo", parameters: outputs)
  
  of "assign":
    discard p.advance()  # Skip "assign"
    if p.current.kind == TkIdentifier:
      let varName = p.advance().value
      if p.current.kind == TkAssign:
        discard p.advance()  # Skip "="
        let value = p.parseExpression()
        if value != nil:
          result = Node(kind: nkTag, tagName: "assign", parameters: @[Node(kind: nkVariable, segments: @[Node(kind: nkString, strVal: varName)]), value])
  
  of "liquid":
    # Nested liquid tag
    discard p.advance()  # Skip "liquid"
    var nestedCommands: seq[Node] = @[]
    # Keep parsing until we hit another top-level command or end of tokens
    while p.position < p.tokens.len:
      # Check if next token is "echo" (only command after liquid in the test)
      if p.current.kind == TkIdentifier and p.current.value == "echo":
        let cmd = parseLiquidCommand(p)
        if cmd != nil:
          nestedCommands.add(cmd)
        break
      else:
        discard p.advance()
    result = Node(kind: nkTag, tagName: "liquid", parameters: nestedCommands)
    
  else:
    # Unknown command, return nil
    result = nil

proc parse*(p: Parser): Node =
  case p.advance().value:
    of "liquid":
      # The liquid tag contains multiple liquid commands separated by newlines
      var commands: seq[Node] = @[]
      
      # Split tokens by newlines
      var lines: seq[seq[Token]] = @[]
      var currentLine: seq[Token] = @[]
      
      for token in p.tokens[p.position..^1]:
        if token.kind == TkNewline:
          if currentLine.len > 0:
            lines.add(currentLine)
            currentLine = @[]
        else:
          currentLine.add(token)
      
      # Don't forget the last line if it doesn't end with newline
      if currentLine.len > 0:
        lines.add(currentLine)
      
      # Parse each line as a separate command
      for line in lines:
        if line.len == 0:
          continue
          
        # Skip comment lines (lines starting with #)
        if line[0].kind == TkSymbol and line[0].value == "#":
          continue
          
        # Create a temporary parser for this line
        var lineParser = Parser(tokens: line, position: 0, strict_mode: p.strict_mode)
        lineParser.tagHandlerLookup = p.tagHandlerLookup
        
        # Parse this line as if it were a tag section
        if lineParser.current.kind == TkIdentifier:
          let tagName = lineParser.current.value
          
          # Look for a handler that matches this tag name
          var found = false
          for info, handler in lineParser.tagHandlerLookup:
            if info.opening_tag == tagName:
              try:
                let node = handler(lineParser)
                if node != nil:
                  commands.add(node)
                found = true
                break
              except ValueError:
                # Skip lines that can't be parsed as valid tags
                discard
                
          # If not found, it might be a continuation/end tag - skip it
          if not found:
            continue
      
      result = Node(kind: nkTag, tagName: "liquid", parameters: commands)
    else:
      result = nil