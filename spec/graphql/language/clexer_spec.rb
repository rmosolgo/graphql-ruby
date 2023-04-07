# frozen_string_literal: true
require "spec_helper"
require_relative "./lexer_examples"

if defined?(GraphQL::CParser::Lexer)
  describe GraphQL::CParser::Lexer do
    subject { GraphQL::CParser::Lexer }

    it "makes tokens like the other lexer" do
      str = "{ f1(arg: \"str\") ...F2 }\nfragment F2 on SomeType { f2 }"
      # Don't include prev_token here
      tokens = GraphQL.scan_with_c(str).map { |t| t.first(4) }
      old_tokens = GraphQL.scan_with_ruby(str).map { |t| t.first(4) }

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
end
