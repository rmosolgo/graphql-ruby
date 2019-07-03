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
        case ast_node
        when GraphQL::Language::Nodes::TypeName
          types.fetch(ast_node.name, nil)
        when GraphQL::Language::Nodes::NonNullType
          ast_inner_type = ast_node.of_type
          inner_type = build_type(types, ast_inner_type)
          wrap_type(inner_type, :to_non_null_type)
        when GraphQL::Language::Nodes::ListType
          ast_inner_type = ast_node.of_type
          inner_type = build_type(types, ast_inner_type)
          wrap_type(inner_type, :to_list_type)
        end
      end

      def self.wrap_type(type, wrapper_method)
        if type.nil?
          nil
        elsif wrapper_method == :to_list_type || wrapper_method == :to_non_null_type
          type.public_send(wrapper_method)
        else
          raise ArgumentError, "Unexpected wrapper method: #{wrapper_method.inspect}"
        end
      end
    end
  end
end
