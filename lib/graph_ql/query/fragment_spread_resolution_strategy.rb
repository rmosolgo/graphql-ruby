class GraphQL::Query::FragmentSpreadResolutionStrategy
  attr_reader :result
  def initialize(ast_fragment_spread, type, target, operation_resolver)
    fragments = operation_resolver.query.fragments
    fragment = fragments[ast_fragment_spread.name]
    if fragment.type != type.type_name
      @result = {}
    else
      selections = fragment.selections
      resolver = GraphQL::Query::SelectionResolver.new(target, type, selections, operation_resolver)
      @result = resolver.result
    end
  end
end
