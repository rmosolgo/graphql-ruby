# frozen_string_literal: true
module GraphQL
  module Language
    # Emitted by the lexer and passed to the parser.
    # Contains type, value and position data.
    class Token
      # @return [Symbol] The kind of token this is
      attr_reader :name, :prev_token, :line

      def initialize(value:, name:, line:, col:, prev_token:)
        @name = name
        @value = value
        @line = line
        @col = col
        @prev_token = prev_token
      end

      def to_s; @value; end
      def to_i; @value.to_i; end
      def to_f; @value.to_f; end

      def line_and_column
        [@line, @col]
      end
    end
  end
end
