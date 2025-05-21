import tables, strutils, sequtils
import ../lexer/types

let tagRules = {
  "if": TagInfo(continuations: @["elsif", "else"], closure: "endif", required: @[]),
  "unless": TagInfo(continuations: @["elsunless", "else"], closure: "endunless", required: @[]),
  "case": TagInfo(continuations: @["when"], closure: "endcase", required: @["when"]),
  "for": TagInfo(continuations: @[], closure: "endfor", required: @[]),
  "capture": TagInfo(continuations: @[], closure: "endcapture", required: @[]),
  # Add other Liquid tags as needed
}.toTable

proc validateTagNesting(sections: seq[Section]): bool =
  var stack: TagStack = @[]
  
  for section in sections:
    if section.sectionType != Tag:
      continue

    let
      node = section.ast
      tagName = ($node.kind).toLower[2..^1]
    
    if tagName in tagRules:
      # Opening tag
      stack.add(TagStackItem(info: tagRules[tagName], hasRequired: false))
    elif stack.len > 0:
      let
        current = stack[^1]
        info = current.info
      if tagName in info.continuations:
        # Valid continuation
        if tagName in info.required:
          stack[^1].hasRequired = true
        continue
      elif tagName == info.closure:
        # Closing tag
        if info.required.len > 0 and not current.hasRequired:
          raise newException(ValueError, "Missing required tag(s) for " & tagName & ": " & info.required.join(", "))
        discard stack.pop()
      else:
        let
          validTags = concat(info.continuations, @[info.closure])
        raise newException(ValueError, "Unexpected tag " & tagName & ", expected one of " & validTags.join(", "))
    else:
      raise newException(ValueError, "Missing opening tag for " & tagName)

  # Check if all tags are closed and required tags are present
  for item in stack:
    if item.info.required.len > 0 and not item.hasRequired:
      raise newException(ValueError, "Unclosed tag missing required child tag(s): " & item.info.required.join(", "))

  result = stack.len == 0  # All tags should be closed



when isMainModule and not defined(release):
  import unittest
  include ../../../test/parser/nesting
