# frozen_string_literal: true
require "spec_helper"
require_relative "./lexer_examples"
describe GraphQL::Language::Lexer do
  subject { GraphQL::Language::Lexer }
  include LexerExamples
end
