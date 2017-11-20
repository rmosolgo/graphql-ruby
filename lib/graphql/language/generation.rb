# frozen_string_literal: true
module GraphQL
  module Language
    # Exposes {.generate}, which turns AST nodes back into query strings.
    module Generation
      extend self

      # Turn an AST node back into a string.
      #
      # @example Turning a document into a query
      #    document = GraphQL.parse(query_string)
      #    GraphQL::Language::Generation.generate(document)
      #    # => "{ ... }"
      #
      # @param node [GraphQL::Language::Nodes::AbstractNode] an AST node to recursively stringify
      # @param indent [String] Whitespace to add to each printed node
      # @return [String] Valid GraphQL for `node`
      def generate(node, indent: "", printer: GraphQL::Language::Printer)
        printer.new(node).print(indent: indent)
      end
    end
  end
end
