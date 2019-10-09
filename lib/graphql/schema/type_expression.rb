# frozen_string_literal: true
module GraphQL
  class Schema
    # @api private
    module TypeExpression
      # Fetch a type from a type map by its AST specification.
      # Return `nil` if not found.
      # @param types [GraphQL::Schema::TypeMap]
      # @param ast_node [GraphQL::Language::Nodes::AbstractNode]
      # @return [GraphQL::BaseType, nil]
      def self.build_type(types, ast_node)
        t = type_from_ast(types, ast_node)
        # maybe nil:
        t ? t.graphql_definition : t
      end

      class << self
        private

        def type_from_ast(types, ast_node)
          case ast_node
          when GraphQL::Language::Nodes::TypeName
            types.fetch(ast_node.name, nil)
          when GraphQL::Language::Nodes::NonNullType
            ast_inner_type = ast_node.of_type
            inner_type = build_type(types, ast_inner_type)
            wrap_type(inner_type, GraphQL::Schema::NonNull)
          when GraphQL::Language::Nodes::ListType
            ast_inner_type = ast_node.of_type
            inner_type = build_type(types, ast_inner_type)
            wrap_type(inner_type, GraphQL::Schema::List)
          end
        end

        def wrap_type(of_type, wrapper)
          if of_type.nil?
            nil
          else
            wrapper.new(of_type)
          end
        end
      end
    end
  end
end
