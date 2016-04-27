module GraphQL
  class Query
    module DirectiveResolution
      def self.include_node?(ast_node, query)
        ast_node.directives.each do |ast_directive|
          directive = query.schema.directives[ast_directive.name]
          args = GraphQL::Query::LiteralInput.from_arguments(ast_directive.arguments, directive.arguments, query.variables)
          if !directive.include?(args)
            return false
          end
        end
        true
      end
    end
  end
end
