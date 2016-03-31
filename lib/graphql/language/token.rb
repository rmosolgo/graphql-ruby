module GraphQL
  module Language
    class Token
      attr_reader :name
      def initialize(value:, name:, line:, col:)
        @name = name
        @value = value
        @line = line
        @col = col
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
