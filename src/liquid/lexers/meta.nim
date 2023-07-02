import parlexgen
import sequtils

import liquid/types
import liquid/lexers/variable

makeLexer meta_lexer*[MetaToken]:
  r"\{\{[^}]*\}\}":
    # echo "match: ", match
    # let
    #   tokens = match.tokens(variable_lexer).to_seq
    MetaToken(kind: VARIABLE, tokens: @[], start_pos: pos, end_pos: pos + match.len - 1, result: "" )

  r"\{%[^}]*%\}": MetaToken(kind: TAG, tokens: @[], start_pos: pos, end_pos: pos + match.len - 1, result: "" )

  r"[^{]+": continue #MetaToken(kind: TEXT, content: match, line: line, start_col: col, end_col: col + match.len )
