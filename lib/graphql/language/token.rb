module GraphQL
  module Language
    # Emitted by the lexer and passed to the parser.
    # Contains type, value and position data.
    class Token
      # @return [Symbol] The kind of token this is
      attr_reader :name, :prev_token, :line

      ### Ruby 1.9.3 unofficial support
      # def initialize(value:, name:, line:, col:, prev_token:)
      def initialize(options = {})
        value = options[:value]
        name = options[:name]
        line = options[:line]
        col = options[:col]
        prev_token = options[:prev_token]

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
