import unittest
import parlexgen
import std/[strutils, sequtils, streams]

import fusion/matching

import parlexgen/common

import liquid/types
import liquid/lexers/meta
import liquid/output

suite "meta lexer":
  test "general lexing":
    let
      html = """
<!DOCTYPE html>
<html>
  <head>
    <meta charSet="utf-8"/>
    <title>{{ page.title }}</title>
  </head>
  <body>
    <h1>{{ page.title }}</h1>
    <ul>
      {% for category in page.categories %}
        <li><a href="{{ category.url }}">{{ category.title }}</a></li>
      {% endfor %}
    </ul>
  </body>
</html>
"""
      generated_tokens = html.tokens(meta_lexer).to_seq

    check: generated_tokens.mapIt( it.kind ) == @[VARIABLE,VARIABLE,TAG,VARIABLE,VARIABLE,TAG]
    check: generated_tokens.mapIt( (it.start_pos, it.end_pos) ) == @[(71, 86), (123, 138), (160, 196), (219, 236), (239, 258), (275, 286)]
    