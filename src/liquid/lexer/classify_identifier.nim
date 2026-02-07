
from ../types import TokenKind

import matches_at

proc classify_identifier*(input: string, start, stop: int): TokenKind  =
  let len = stop - start
  
  case input[start]
  of 'a':
    if len == 3 and input.matchesAt(start + 1, "nd"): return tkAnd
    if len == 6 and input.matchesAt(start + 1, "ssign"): return tkAssignTag
  of 'b':
    if len == 5 and input.matchesAt(start + 1, "reak"): return tkBreak
  of 'c':
    if len == 4 and input.matchesAt(start + 1, "ase"): return tkCase
    if len == 8 and input.matchesAt(start + 1, "ontinue"): return tkContinue
    if len == 8 and input.matchesAt(start + 1, "ontains"): return tkContains
    if len == 7 and input.matchesAt(start + 1, "apture"): return tkCapture
  of 'e':
    if len == 4 and input.matchesAt(start + 1, "lse"): return tkElse
    if len == 5 and input.matchesAt(start + 1, "lsif"): return tkElsif
    if len == 5 and input.matchesAt(start + 1, "ndif"): return tkEndif
    if len == 5 and input.matchesAt(start + 1, "mpty"): return tkEmpty
    if len == 6 and input.matchesAt(start + 1, "lseif"): return tkElsif
    if len == 6 and input.matchesAt(start + 1, "ndfor"): return tkEndfor
    if len == 7 and input.matchesAt(start + 1, "ndcase"): return tkEndcase
    if len == 9 and input.matchesAt(start + 1, "ndunless"): return tkEndunless
    if len == 10 and input.matchesAt(start + 1, "ndcapture"): return tkEndcapture
  of 'f':
    if len == 3 and input.matchesAt(start + 1, "or"): return tkFor
    if len == 5 and input.matchesAt(start + 1, "alse"): return tkFalse
  of 'i':
    if len == 2 and input.matchesAt(start + 1, 'f'): return tkIf
    if len == 2 and input.matchesAt(start + 1, 'n'): return tkIn
  of 'l':
    if len == 6 and input.matchesAt(start + 1, "iquid"): return tkLiquid
  of 'n':
    if len == 3 and input.matchesAt(start + 1, "ot"): return tkNot
    if len == 3 and input.matchesAt(start + 1, "il"): return tkNil
    if len == 4 and input.matchesAt(start + 1, "ull"): return tkNil
  of 'o':
    if len == 2 and input.matchesAt(start + 1, 'r'): return tkOr
  of 't':
    if len == 4 and input.matchesAt(start + 1, "rue"): return tkTrue
  of 'u':
    if len == 6 and input.matchesAt(start + 1, "nless"): return tkUnless
  of 'w':
    if len == 4 and input.matchesAt(start + 1, "hen"): return tkWhen
  else:
    discard
  return tkIdentifier



when isMainModule:
  import std/[unittest, strformat, times, monotimes]

  suite "Keyword Classifier Tests":
    test "Length 2 keywords":
      let input = "if or in xx"
      check classify_identifier(input, 0, 2) == tkIf
      check classify_identifier(input, 3, 5) == tkOr
      check classify_identifier(input, 6, 8) == tkIn
      check classify_identifier(input, 9, 11) == tkIdentifier  # "xx" is not a keyword
    
    test "Length 3 keywords":
      let input = "for and not nil foo"
      check classify_identifier(input, 0, 3) == tkFor
      check classify_identifier(input, 4, 7) == tkAnd
      check classify_identifier(input, 8, 11) == tkNot
      check classify_identifier(input, 12, 15) == tkNil
      check classify_identifier(input, 16, 19) == tkIdentifier  # "foo" is not a keyword
    
    test "Length 4 keywords":
      let input = "else case when null true blah"
      check classify_identifier(input, 0, 4) == tkElse
      check classify_identifier(input, 5, 9) == tkCase
      check classify_identifier(input, 10, 14) == tkWhen
      check classify_identifier(input, 15, 19) == tkNil  # "null" maps to tkNil
      check classify_identifier(input, 20, 24) == tkTrue
      check classify_identifier(input, 25, 29) == tkIdentifier  # "blah" is not a keyword
    
    test "Length 5 keywords":
      let input = "elsif endif break false empty nope!"
      check classify_identifier(input, 0, 5) == tkElsif
      check classify_identifier(input, 6, 11) == tkEndif
      check classify_identifier(input, 12, 17) == tkBreak
      check classify_identifier(input, 18, 23) == tkFalse
      check classify_identifier(input, 24, 29) == tkEmpty
      check classify_identifier(input, 30, 35) == tkIdentifier  # "nope!" is not a keyword
    
    test "Length 6 keywords":
      let input = "elseif unless endfor liquid assign foobar"
      check classify_identifier(input, 0, 6) == tkElsif  # "elseif" alternative spelling
      check classify_identifier(input, 7, 13) == tkUnless
      check classify_identifier(input, 14, 20) == tkEndfor
      check classify_identifier(input, 21, 27) == tkLiquid
      check classify_identifier(input, 28, 34) == tkAssignTag
      check classify_identifier(input, 35, 41) == tkIdentifier  # "foobar" is not a keyword
    
    test "Length 7 keywords":
      let input = "capture endcase nothing"
      check classify_identifier(input, 0, 7) == tkCapture
      check classify_identifier(input, 8, 15) == tkEndcase
      check classify_identifier(input, 16, 23) == tkIdentifier  # "nothing" is not a keyword
    
    test "Length 8 keywords":
      let input = "continue contains someword"
      check classify_identifier(input, 0, 8) == tkContinue
      check classify_identifier(input, 9, 17) == tkContains
      check classify_identifier(input, 18, 26) == tkIdentifier  # "someword" is not a keyword
    
    test "Length 9 keywords":
      let input = "endunless something"
      check classify_identifier(input, 0, 9) == tkEndunless
      check classify_identifier(input, 10, 19) == tkIdentifier  # "something" is not a keyword
    
    test "Length 10 keywords":
      let input = "endcapture randomword"
      check classify_identifier(input, 0, 10) == tkEndcapture
      check classify_identifier(input, 11, 21) == tkIdentifier  # "randomword" is not a keyword
    
    test "Edge cases":
      let input = "i fo no nul tru fals empt"
      # Too short or incomplete keywords
      check classify_identifier(input, 0, 1) == tkIdentifier  # "i" is not "if"
      check classify_identifier(input, 2, 4) == tkIdentifier  # "fo" is not "for"
      check classify_identifier(input, 5, 7) == tkIdentifier  # "no" is not "not"
      check classify_identifier(input, 8, 11) == tkIdentifier  # "nul" is not "null"
      check classify_identifier(input, 12, 15) == tkIdentifier  # "tru" is not "true"
      check classify_identifier(input, 16, 20) == tkIdentifier  # "fals" is not "false"
      check classify_identifier(input, 21, 25) == tkIdentifier  # "empt" is not "empty"
    
    test "Case sensitivity":
      let input = "IF Or NOT False TRUE"
      # Keywords should be case-sensitive
      check classify_identifier(input, 0, 2) == tkIdentifier  # "IF" is not "if"
      check classify_identifier(input, 3, 5) == tkIdentifier  # "Or" is not "or"
      check classify_identifier(input, 6, 9) == tkIdentifier  # "NOT" is not "not"
      check classify_identifier(input, 10, 15) == tkIdentifier  # "False" is not "false"
      check classify_identifier(input, 16, 20) == tkIdentifier  # "TRUE" is not "true"
    
    test "Similar but different words":
      let input = "iffy fork noting nils truly falsely"
      check classify_identifier(input, 0, 4) == tkIdentifier  # "iffy" is not a keyword
      check classify_identifier(input, 5, 9) == tkIdentifier  # "fork" is not a keyword
      check classify_identifier(input, 10, 16) == tkIdentifier  # "noting" is not a keyword
      check classify_identifier(input, 17, 21) == tkIdentifier  # "nils" is not a keyword
      check classify_identifier(input, 22, 27) == tkIdentifier  # "truly" is not a keyword
      check classify_identifier(input, 28, 35) == tkIdentifier  # "falsely" is not a keyword
    
  suite "Performance benchmark":
    test "classify_identifier":
      let testInput = "if for assign endcapture liquid else when continue break unless"
      let positions = @[
        (0, 2, tkIf),
        (3, 6, tkFor),
        (7, 13, tkAssignTag),
        (14, 24, tkEndcapture),
        (25, 31, tkLiquid),
        (32, 36, tkElse),
        (37, 41, tkWhen),
        (42, 50, tkContinue),
        (51, 56, tkBreak),
        (57, 63, tkUnless)
      ]
      
      let iterations = 1_000_000
      let start = getMonoTime()
      
      for i in 0..<iterations:
        for (startPos, endPos, expectedToken) in positions:
          let token = classify_identifier(testInput, startPos, endPos)
          doAssert token == expectedToken
      
      let elapsed = getMonoTime() - start
      let totalChecks = iterations * positions.len
      let nanosPerCheck = elapsed.inNanoseconds.float / totalChecks.float
      let checksPerSecond = 1_000_000_000.0 / nanosPerCheck
      
      echo fmt"Performance: {nanosPerCheck:.2f}ns per classification"
      echo fmt"Throughput: {checksPerSecond/1_000_000:.1f}M classifications/sec"
      
      # Should be well under 10ns per check on modern hardware
      check nanosPerCheck < 10.0
