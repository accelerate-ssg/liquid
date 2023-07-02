import unittest
import parlexgen
import std/[strutils, sequtils, streams]

import fusion/matching

import parlexgen/common

import liquid/types
import liquid/lexers/variable

suite "variable lexer":
  test "simple filter":
    let
      tag = "{{ foo | bar }}"
      tokens = tag.tokens(variable_lexer).to_seq

    check: tokens.mapIt( it.kind ) == @[IDENTIFIER, PIPE, IDENTIFIER]
    check: tokens[0].identifier_name == "foo"
    check: tokens[2].identifier_name == "bar"

  test "filter with string argument":
    let
      tag = "{{ foo | bar: \"test\" }}"
      tokens = tag.tokens(variable_lexer).to_seq

    check: tokens.mapIt( it.kind ) == @[IDENTIFIER, PIPE, IDENTIFIER, COLON, STRING_LITERAL]
    check: tokens[0].identifier_name == "foo"
    check: tokens[2].identifier_name == "bar"
    check: tokens[4].string_value == "test"

  test "filter with int argument":
    let
      tag = "{{ foo | bar: 12 }}"
      tokens = tag.tokens(variable_lexer).to_seq

    check: tokens.mapIt( it.kind ) == @[IDENTIFIER, PIPE, IDENTIFIER, COLON, INTEGER_LITERAL]
    check: tokens[0].identifier_name == "foo"
    check: tokens[2].identifier_name == "bar"
    check: tokens[4].integer_value == 12

  test "filter with float argument":
    let
      tag = "{{ foo | bar: 12.0 }}"
      tokens = tag.tokens(variable_lexer).to_seq

    check: tokens.mapIt( it.kind ) == @[IDENTIFIER, PIPE, IDENTIFIER, COLON, FLOAT_LITERAL]
    check: tokens[0].identifier_name == "foo"
    check: tokens[2].identifier_name == "bar"
    check: tokens[4].float_value == 12.0

  test "filter with several arguments":
    let
      tag = "{{ foo | bar: \"test\", 12, 12.0 }}"
      tokens = tag.tokens(variable_lexer).to_seq

    check: tokens.mapIt( it.kind ) == @[IDENTIFIER, PIPE, IDENTIFIER, COLON, STRING_LITERAL, COMMA, INTEGER_LITERAL, COMMA, FLOAT_LITERAL]
    check: tokens[0].identifier_name == "foo"
    check: tokens[2].identifier_name == "bar"
    check: tokens[4].string_value == "test"
    check: tokens[6].integer_value == 12
    check: tokens[8].float_value == 12.0

  test "several filters":
    let
      tag = "{{ foo | bar | baz }}"
      tokens = tag.tokens(variable_lexer).to_seq

    check: tokens.mapIt( it.kind ) == @[IDENTIFIER, PIPE, IDENTIFIER, PIPE, IDENTIFIER]
    check: tokens[0].identifier_name == "foo"
    check: tokens[2].identifier_name == "bar"
    check: tokens[4].identifier_name == "baz"

  test "several filters with arguments":
    let
      tag = "{{ foo | bar: \"test\", 12, 12.0 | baz: \"tezt\", 42, 3.1415 }}"
      tokens = tag.tokens(variable_lexer).to_seq

    check: tokens.mapIt( it.kind ) == @[IDENTIFIER, PIPE, IDENTIFIER, COLON, STRING_LITERAL, COMMA, INTEGER_LITERAL, COMMA, FLOAT_LITERAL, PIPE, IDENTIFIER, COLON, STRING_LITERAL, COMMA, INTEGER_LITERAL, COMMA, FLOAT_LITERAL]
    check: tokens[0].identifier_name == "foo"
    check: tokens[2].identifier_name == "bar"
    check: tokens[4].string_value == "test"
    check: tokens[6].integer_value == 12
    check: tokens[8].float_value == 12.0
    check: tokens[10].identifier_name == "baz"
    check: tokens[12].string_value == "tezt"
    check: tokens[14].integer_value == 42
    check: tokens[16].float_value == 3.1415
