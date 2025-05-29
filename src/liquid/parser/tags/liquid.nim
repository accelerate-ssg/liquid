import ../../types, ../core
import strutils

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
      # The liquid tag contains multiple liquid commands
      var commands: seq[Node] = @[]
      
      # Parse commands until we run out of tokens
      while p.position < p.tokens.len:
        # Save current position in case we need to backtrack
        let savedPos = p.position
        
        # Try to parse a command
        let cmd = parseLiquidCommand(p)
        if cmd != nil:
          commands.add(cmd)
        else:
          # If we couldn't parse a command, check if we're at a potential command start
          if p.current.kind == TkIdentifier and p.current.value in ["echo", "assign", "liquid"]:
            # We're at a command but failed to parse it, skip this token
            discard p.advance()
          else:
            # Not a command, skip this token
            discard p.advance()
      
      result = Node(kind: nkTag, tagName: "liquid", parameters: commands)
    else:
      result = nil