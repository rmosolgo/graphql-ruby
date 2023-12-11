# frozen_string_literal: true
require "spec_helper"
require_relative "./lexer_examples"
describe GraphQL::Language::Lexer do
  class Tokenizer
    def self.tokenize(string)
      lexer = GraphQL::Language::Lexer.new(string)
      tokens = []
      prev_token = nil
      while (token_name = lexer.advance)
        new_token = [
          token_name,
          lexer.line_number,
          lexer.column_number,
          lexer.debug_token_value(token_name),
          prev_token,
        ]
        tokens << new_token
        prev_token = new_token
      end
      tokens
    end
  end
  subject { Tokenizer }
  include LexerExamples
end
