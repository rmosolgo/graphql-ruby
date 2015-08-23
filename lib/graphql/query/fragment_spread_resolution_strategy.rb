class GraphQL::Query::FragmentSpreadResolutionStrategy
  attr_reader :result
  def initialize(ast_fragment_spread, type, target, query)
    fragments = query.fragments
    fragment_def = fragments[ast_fragment_spread.name]
    child_type = query.schema.types[fragment_def.type]
    resolved_type = GraphQL::Query::TypeResolver.new(target, child_type, type).type
    if resolved_type.nil?
      @result = {}
    else
      selections = fragment_def.selections
      resolver = GraphQL::Query::SelectionResolver.new(target, resolved_type, selections, query)
      @result = resolver.result
    end
  end
end
