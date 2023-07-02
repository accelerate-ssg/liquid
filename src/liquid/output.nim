import streams,strutils

import liquid/types



proc rewind*(input: Stream, start_pos: int, end_pos: int): int =
  input.setPosition(start_pos)
  let
    buffer = input.readStr(end_pos - start_pos + 1).strip( leading = false )
    original_length = end_pos - start_pos + 1

  return original_length - buffer.len

proc fast_forward*( input: Stream ) =
  while input.peekChar in Whitespace:
    discard input.readChar

#TODO: Add support for whitespace control https://shopify.github.io/liquid/basics/whitespace/
proc replace*( input: Stream, output: Stream, replacements: seq[MetaToken] ) =
  input.setPosition(0)

  for replacement in replacements:
    let
      start_pos = replacement.start_pos
      end_pos = replacement.end_pos
      last_end_pos = input.get_position
    
    output.write(input.read_str(start_pos - last_end_pos))

    if replacement.tokens.len > 0 and replacement.tokens[0].kind == WHITESPACE_CONTROL:
      let
        number_of_characters = input.rewind(last_end_pos, start_pos - 1)

      if number_of_characters > 0:
        output.set_position(output.get_position - number_of_characters)
        
    output.write(replacement.result)
    input.setPosition(end_pos + 1)

    if replacement.tokens.len > 0 and replacement.tokens[^1].kind == WHITESPACE_CONTROL:
      fast_forward(input)

  output.write(input.readAll())
