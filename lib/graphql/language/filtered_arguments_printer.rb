# frozen_string_literal: true
module GraphQL
  module Language
    class FilteredArgumentsPrinter < Printer
      # Turn an arbitrary AST node back into a string with argument values filtered.
      # By default, the replacement is <FILTERED>
      #
      # @example Turning a document into a query string
      #    document = GraphQL.parse(query_string)
      #    GraphQL::Language::Printer.new.print(document)
      #    # => "{ ... }"
      #
      #
      attr_reader :redaction
      def initialize(redaction: '<FILTERED>')
        @redaction = GraphQL::Language.serialize(redaction)
      end

      # @param indent [String] Whitespace to add to the printed node
      # @return [String] Valid GraphQL for `node`
      def print(node, indent: "")
        print_node(node, indent: indent)
      end

      protected

      def print_scalar(node)
        redaction
      end

      def print_argument(argument)
        value = argument.value.is_a?(String) ? redaction : argument.value
        "#{argument.name}: #{print_node(value)}".dup
      end
    end
  end
end
