# frozen_string_literal: true
module GraphQL
  module Language
    # Emitted by the lexer and passed to the parser.
    # Contains type, value and position data.
    class Token
      if !String.method_defined?(:-@)
        using GraphQL::StringDedupBackport
      end

      # @return [Symbol] The kind of token this is
      attr_reader :name
      # @return [String] The text of this token
      attr_reader :value
      attr_reader :prev_token, :line, :col

      def initialize(name, value, line, col, prev_token)
        @name = name
        @value = -value
        @line = line
        @col = col
        @prev_token = prev_token
      end

      alias to_s value
      def to_i; @value.to_i; end
      def to_f; @value.to_f; end

      def line_and_column
        [@line, @col]
      end

      def inspect
        "(#{@name} #{@value.inspect} [#{@line}:#{@col}])"
      end
    end
  end
end
