import unittest, streams

import liquid/output
import liquid/types

suite "output procs":

  setup:
    let
      input = newStringStream("<html>\n  <head>\n    <title>\n      {{ page.title }}\n    </title>\n  </head>\n  <body>\n    <h1>{{ page.title }}</h1>\n    {{ content }}\n  </body>\n</html>")

  test "rewind to start of line":
    let
      pos = input.rewind( 0, 33 )

    check pos == 7

  test "try to rewind when there is no leading whitespace":
    let
      pos = input.rewind( 49, 90 )

    check pos == 0

  test "fast forward to end of line":
    input.set_position(50)
    input.fast_forward()

    check input.get_position == 55

  test "try to fast forward when there is no trailing whitespace":
    input.set_position(106)
    input.fast_forward()

    check input.get_position == 106

  test "Replace tag leaving leading and trailing whitespace":
    let
      tokens = @[
        MetaToken(
          kind: VARIABLE,
          tokens: @[Token( kind: IDENTIFIER, identifier_name: "page.title" )],
          start_pos: 34,
          end_pos: 49,
          result: "AMAZING!!"
        ),
        MetaToken(
          kind: VARIABLE,
          tokens: @[Token( kind: IDENTIFIER, identifier_name: "page.title" )],
          start_pos: 91,
          end_pos: 106,
          result: "AMAZING!!"
        )
      ]
      output = newStringStream()
    
    input.replace( output, tokens )

    output.set_position(0)
    check output.readAll == "<html>\n  <head>\n    <title>\n      AMAZING!!\n    </title>\n  </head>\n  <body>\n    <h1>AMAZING!!</h1>\n    {{ content }}\n  </body>\n</html>"
  
  test "Replace tag removing leading and trailing whitespace":
    let
      tokens = @[
        MetaToken(
          kind: VARIABLE,
          tokens: @[Token( kind: WHITESPACE_CONTROL )],
          start_pos: 34,
          end_pos: 49,
          result: "AMAZING!!"
        ),
        MetaToken(
          kind: VARIABLE,
          tokens: @[Token( kind: WHITESPACE_CONTROL )],
          start_pos: 91,
          end_pos: 106,
          result: "AMAZING!!"
        )
      ]
      output = newStringStream()

    input.replace( output, tokens )

    output.set_position(0)
    check output.readAll == "<html>\n  <head>\n    <title>AMAZING!!</title>\n  </head>\n  <body>\n    <h1>AMAZING!!</h1>\n    {{ content }}\n  </body>\n</html>"

