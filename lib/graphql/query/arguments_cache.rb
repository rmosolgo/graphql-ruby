# frozen_string_literal: true
module GraphQL
  class Query
    module ArgumentsCache
      # @return [Hash<InternalRepresentation::Node, GraphQL::Language::NodesDirectiveNode => Hash<GraphQL::Field, GraphQL::Directive => GraphQL::Query::Arguments>>]
      def self.build(query)
        Hash.new do |h1, irep_or_ast_node|
          Hash.new do |h2, definition|
            ast_node = irep_or_ast_node.is_a?(GraphQL::InternalRepresentation::Node) ? irep_or_ast_node.ast_node : irep_or_ast_node
            ast_arguments = ast_node.arguments
            if ast_arguments.none?
              definition.default_arguments
            else
              GraphQL::Query::LiteralInput.from_arguments(
                ast_arguments,
                definition.arguments,
                query.variables,
              )
            end
          end
        end
      end
    end
  end
end
