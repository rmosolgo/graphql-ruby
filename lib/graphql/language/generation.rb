# frozen_string_literal: true
module GraphQL
  module Language
    # Exposes [.generate](rdoc-ref:.generate), which turns AST nodes back into query strings.
    module Generation
      extend self

      # Turn an AST node back into a string.
      #
      # **Examples**
      #
      # **Example: Turning a document into a query**
      #
      # ```ruby
      # document = GraphQL.parse(query_string)
      # GraphQL::Language::Generation.generate(document)
      # # => "{ ... }"
      # ```
      #
      # **Parameters**
      #
      # - `node` (`GraphQL::Language::Nodes::AbstractNode`) — an AST node to recursively stringify
      # - `indent` (`String`) — Whitespace to add to each printed node
      # - `printer` (`GraphQL::Language::Printer`) — An optional custom printer for printing AST nodes. Defaults to GraphQL::Language::Printer
      #
      # **Returns**
      #
      # - `String` — Valid GraphQL for `node`
      #
      # :call-seq:
      #   generate(GraphQL::Language::Nodes::AbstractNode node, String indent:, GraphQL::Language::Printer printer:) -> String
      def generate(node, indent: "", printer: GraphQL::Language::Printer.new)
        printer.print(node, indent: indent)
      end
    end
  end
end
