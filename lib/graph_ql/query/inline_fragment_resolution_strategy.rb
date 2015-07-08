class GraphQL::Query::InlineFragmentResolutionStrategy
  attr_reader :result
  def initialize(ast_inline_fragment, type, target, operation_resolver)
    if ast_inline_fragment.type != type.name
      @result = {}
    else
      selections = ast_inline_fragment.selections
      resolver = GraphQL::Query::SelectionResolver.new(target, type, selections, operation_resolver)
      @result = resolver.result
    end
  end
end
