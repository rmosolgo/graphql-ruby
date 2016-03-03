module GraphQL
  class Schema
    class TypeExpression
      def initialize(schema, ast_node)
        @schema = schema
        @ast_node = ast_node
      end

      def type
        @type ||= build_type(@schema, @ast_node)
      end

      private

      def build_type(schema, ast_node)
        if ast_node.is_a?(GraphQL::Language::Nodes::TypeName)
          type_name = ast_node.name
          schema.types[type_name]
        elsif ast_node.is_a?(GraphQL::Language::Nodes::NonNullType)
          ast_inner_type = ast_node.of_type
          build_type(schema, ast_inner_type).to_non_null_type
        elsif ast_node.is_a?(GraphQL::Language::Nodes::ListType)
          ast_inner_type = ast_node.of_type
          build_type(schema, ast_inner_type).to_list_type
        end
      end
    end
  end
end
