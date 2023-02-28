# frozen_string_literal: true
require "spec_helper"
require_relative "./lexer_examples"

# TODO dry with lexer_spec.rb
describe GraphQL::Clexer do
  subject { GraphQL::Clexer }

  it "makes tokens like the other lexer" do
    str = "{ f1(arg: \"str\") ...F2 }\nfragment F2 on SomeType { f2 }"
    # Don't include prev_token here
    tokens = subject.tokenize(str).map { |t| [t[0], t[1], t[2], t[3]]}
    old_tokens = GraphQL.scan_with_ragel(str).map { |t|
      [t.name, t.line, t.col, t.value]
    }

    assert_equal [
      [:LCURLY, 1, 1, "{"],
      [:IDENTIFIER, 1, 3, "f1"],
      [:LPAREN, 1, 5, "("],
      [:IDENTIFIER, 1, 6, "arg"],
      [:COLON, 1, 9, ":"],
      [:STRING, 1, 11, "str"],
      [:RPAREN, 1, 16, ")"],
      [:ELLIPSIS, 1, 18, "..."],
      [:IDENTIFIER, 1, 21, "F2"],
      [:RCURLY, 1, 24, "}"],
      [:FRAGMENT, 2, 1, "fragment"],
      [:IDENTIFIER, 2, 10, "F2"],
      [:ON, 2, 13, "on"],
      [:IDENTIFIER, 2, 16, "SomeType"],
      [:LCURLY, 2, 25, "{"],
      [:IDENTIFIER, 2, 27, "f2"],
      [:RCURLY, 2, 30, "}"]
    ], tokens
    assert_equal(old_tokens, tokens)
  end

  include LexerExamples
end
