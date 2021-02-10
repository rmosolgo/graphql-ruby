# frozen_string_literal: true
module GraphQL
  class Query
    module ArgumentsCache
      # @return [Hash<InternalRepresentation::Node, GraphQL::Language::NodesDirectiveNode => Hash<GraphQL::Field, GraphQL::Directive => GraphQL::Query::Arguments>>]
      def self.build(query)
        Hash.new do |h1, irep_or_ast_node|
          h1[irep_or_ast_node] = Hash.new do |h2, definition|
            ast_node = irep_or_ast_node.is_a?(GraphQL::InternalRepresentation::Node) ? irep_or_ast_node.ast_node : irep_or_ast_node
            h2[definition] = if definition.arguments.empty?
              GraphQL::Query::Arguments::NO_ARGS
            else
              GraphQL::Query::LiteralInput.from_arguments(
                ast_node.arguments,
                definition,
                query.variables,
              )
            end
          end
        end
      end
    end
  end
end
