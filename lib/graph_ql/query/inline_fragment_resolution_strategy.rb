class GraphQL::Query::InlineFragmentResolutionStrategy
  attr_reader :result
  def initialize(ast_inline_fragment, type, target, operation_resolver)
    resolved_type = GraphQL::Query::TypeResolver.new(target, ast_inline_fragment.type, type).type
    if resolved_type.nil?
      @result = {}
    else
      selections = ast_inline_fragment.selections
      resolver = GraphQL::Query::SelectionResolver.new(target, resolved_type, selections, operation_resolver)
      @result = resolver.result
    end
  end
end
