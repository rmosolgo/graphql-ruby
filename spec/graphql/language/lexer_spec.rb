# frozen_string_literal: true
require "spec_helper"
require_relative "./lexer_examples"
describe GraphQL::Language::Lexer do
  subject { GraphQL::Language::Lexer }
  include LexerExamples

  def assert_bad_unicode(string, expected_err_message = "Parse error on bad Unicode escape sequence")
    err = assert_raises(GraphQL::ParseError) do
      subject.tokenize(string)
    end
    assert_equal expected_err_message, err.message
  end

  it "rejects unicode escapes outside the valid range" do
    assert_bad_unicode('"\\u{FFFFFFFFFF}"', 'Bad unicode escape in "\\\\u{FFFFFFFFFF}"')
  end

  it "reports positions correctly after multibyte input" do
    err = assert_raises(GraphQL::ParseError) do
      subject.tokenize("{\n  # 日本語\n  field(arg: -foo)\n}")
    end

    assert_equal 3, err.line
    assert_equal 14, err.col
  end

  it "reports column one after a newline" do
    tokens = subject.tokenize("{ field }\n# 日本語\nfragment F on Type { field }")
    fragment_token = tokens.find { |token| token.first == :FRAGMENT }

    assert_equal [:FRAGMENT, 3, 1, "fragment"], fragment_token
  end

  it "reraises unexpected argument errors" do
    lexer = subject.new("{")
    scanner = lexer.instance_variable_get(:@scanner)

    scanner.stub(:skip, ->(*) { raise ArgumentError, "unexpected failure" }) do
      err = assert_raises(ArgumentError) { lexer.advance }
      assert_equal "unexpected failure", err.message
    end
  end
end
