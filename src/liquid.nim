import parlexgen

import liquid/parser

echo parse(
  dedent"""
    foo = (1+3) * 3;
    out foo;
    b = foo * 2;
    out b
  """,
  lex
)
