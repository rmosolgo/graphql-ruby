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

  it "reports positions correctly after multibyte input" do
    err = assert_raises(GraphQL::ParseError) do
      subject.tokenize("{\n  # 日本語\n  field(arg: -foo)\n}")
    end

    assert_equal 3, err.line
    assert_equal 14, err.col
  end
end
