module GraphQL
  class Schema
    module TypeExpression
      def self.build_type(schema, ast_node)
        case ast_node
        when GraphQL::Language::Nodes::TypeName
          type_name = ast_node.name
          schema.types.fetch(type_name, GraphQL::StaticAnalysis::TypeCheck::AnyType)
        when GraphQL::Language::Nodes::NonNullType
          ast_inner_type = ast_node.of_type
          build_type(schema, ast_inner_type).to_non_null_type
        when GraphQL::Language::Nodes::ListType
          ast_inner_type = ast_node.of_type
          build_type(schema, ast_inner_type).to_list_type
        end
      end
    end
  end
end
