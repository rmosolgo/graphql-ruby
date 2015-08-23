class GraphQL::Query::InlineFragmentResolutionStrategy
  attr_reader :result
  def initialize(ast_inline_fragment, type, target, query)
    child_type = query.schema.types[ast_inline_fragment.type]
    resolved_type = GraphQL::Query::TypeResolver.new(target, child_type, type).type
    if resolved_type.nil?
      @result = {}
    else
      selections = ast_inline_fragment.selections
      resolver = GraphQL::Query::SelectionResolver.new(target, resolved_type, selections, query)
      @result = resolver.result
    end
  end
end
