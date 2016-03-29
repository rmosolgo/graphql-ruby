class GraphQL::Query::DirectiveResolution
  def self.include_node?(ast_node, query)
    ast_node.directives.each do |ast_directive|
      directive = query.schema.directives[ast_directive.name]
      args = GraphQL::Query::LiteralInput.from_arguments(ast_directive.arguments, directive.arguments, query.variables)
      return false unless directive.include?(args)
    end
    true
  end
end
