import unittest
import parlexgen
import std/[strutils, sequtils, streams]

import fusion/matching

import parlexgen/common

import liquid/types
import liquid/lexers/variable

suite "variable lexer":
  test "pure identifier":
    let
      tag = "{{ foo }}"
      tokens = tag.tokens(variable_lexer).to_seq

    check: tokens.mapIt( it.kind ) == @[IDENTIFIER]
    check: tokens.mapIt( it.identifier_name ) == @["foo"]
    
  test "capitalized pure identifier":
    let
      tag = "{{ Foo }}"
      tokens = tag.tokens(variable_lexer).to_seq

    check: tokens.mapIt( it.kind ) == @[IDENTIFIER]
    check: tokens.mapIt( it.identifier_name ) == @["Foo"]

  test "all caps pure identifier":
    let
      tag = "{{ FOO }}"
      tokens = tag.tokens(variable_lexer).to_seq

    check: tokens.mapIt( it.kind ) == @[IDENTIFIER]
    check: tokens.mapIt( it.identifier_name ) == @["FOO"]

  test "dotted identifier":
    let
      tag = "{{ page.title }}"
      tokens = tag.tokens(variable_lexer).to_seq

    check: tokens.mapIt( it.kind ) == @[IDENTIFIER]
    check: tokens.mapIt( it.identifier_name ) == @["page.title"]

  test "dashed identifier":
    let
      tag = "{{ page-title }}"
      tokens = tag.tokens(variable_lexer).to_seq

    check: tokens.mapIt( it.kind ) == @[IDENTIFIER]
    check: tokens.mapIt( it.identifier_name ) == @["page-title"]

  test "underscored identifier":
    let
      tag = "{{ page_title }}"
      tokens = tag.tokens(variable_lexer).to_seq

    check: tokens.mapIt( it.kind ) == @[IDENTIFIER]
    check: tokens.mapIt( it.identifier_name ) == @["page_title"]

  test "identifier with number":
    let
      tag = "{{ page.title1 }}"
      tokens = tag.tokens(variable_lexer).to_seq

    check: tokens.mapIt( it.kind ) == @[IDENTIFIER]
    check: tokens.mapIt( it.identifier_name ) == @["page.title1"]
