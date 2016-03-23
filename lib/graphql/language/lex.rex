class GraphQL::Language::RaccParser
macro
  IDENTIFIER    [_A-Za-z][_0-9A-Za-z]*
  BLANK         [\s\n,]+
  COMMENT       \#[^\n\r]*
  INT           -?(0|[1-9][0-9]*)
  FLOAT         -?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?
  ON            on
  FRAGMENT      fragment
  TRUE          true
  FALSE         false

  RCURLY        \{
  LCURLY        \}
  RPAREN        \(
  LPAREN        \)
  RBRACKET      \[
  LBRACKET      \]
  COLON         \:
  QUOTE         \"
  ESCAPED_QUOTE \\"
  ESCAPED_N     \\n
  ESCAPED_R     \\r
  ESCAPED_B     \\b
  ESCAPED_T     \\t
  ESCAPED_F     \\f
  ESCAPED_U     \\u[\dA-Fa-f]{4}
  STR_CHAR      [^\x00-\x1f\\\x22]+
  VAR_SIGN      \$
  DIR_SIGN      @
  ELLIPSIS      \.\.\.
  EQUALS        =
  BANG          !

rule
        {BLANK}
        {COMMENT}
        {RCURLY}        { [:RCURLY, text] }
        {LCURLY}        { [:LCURLY, text] }
        {RPAREN}        { [:RPAREN, text] }
        {LPAREN}        { [:LPAREN, text] }
        {RBRACKET}      { [:RBRACKET, text] }
        {LBRACKET}      { [:LBRACKET, text] }
        {COLON}         { [:COLON, text] }
        {FLOAT}         { [:FLOAT, text] }
        {INT}           { [:INT, text] }
        {QUOTE}         { self.state = :STRING; self.string_buffer = ""; nil }
:STRING {STR_CHAR}      { self.string_buffer << text; nil }
:STRING {ESCAPED_QUOTE} { self.string_buffer << '"'.freeze; nil }
:STRING {ESCAPED_N}     { self.string_buffer << "\n".freeze; nil }
:STRING {ESCAPED_R}     { self.string_buffer << "\r".freeze; nil }
:STRING {ESCAPED_B}     { self.string_buffer << "\b".freeze; nil }
:STRING {ESCAPED_T}     { self.string_buffer << "\t".freeze; nil }
:STRING {ESCAPED_F}     { self.string_buffer << "\f".freeze; nil }
:STRING {ESCAPED_U}     { self.string_buffer << text.gsub(UTF_8, &UTF_8_REPLACE); nil }
:STRING {QUOTE}         { self.state = nil; str = self.string_buffer; [:STRING, str] }
        {TRUE}          { [:TRUE, text] }
        {FALSE}         { [:FALSE, text] }
        {VAR_SIGN}      { [:VAR_SIGN, text] }
        {DIR_SIGN}      { [:DIR_SIGN, text] }
        {ELLIPSIS}      { [:ELLIPSIS, text] }
        {ON}            { [:ON, text] }
        {FRAGMENT}      { [:FRAGMENT, text] }
        {EQUALS}        { [:EQUALS, text] }
        {BANG}          { [:BANG, text] }
        {IDENTIFIER}    { [:IDENTIFIER, text] }

inner

attr_accessor :string_buffer

UTF_8 = /\\u[\da-f]{4}/i
UTF_8_REPLACE = -> (m) { [m[-4..-1].to_i(16)].pack('U') }

end
