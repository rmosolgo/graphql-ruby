class GraphQL::Query::FragmentSpreadResolutionStrategy
  attr_reader :ast_fragment_spread, :type, :target, :query, :ast_fragment, :resolved_type
  def initialize(ast_fragment_spread, type, target, query)
    @ast_fragment_spread = ast_fragment_spread
    @type = type
    @target = target
    @query = query
    @ast_fragment = query.fragments[ast_fragment_spread.name]
    child_type = query.schema.types[ast_fragment.type]
    @resolved_type = GraphQL::Query::TypeResolver.new(target, child_type, type).type
  end

  def result
    return {} if resolved_type.nil?
    selections = ast_fragment.selections
    resolver = GraphQL::Query::SelectionResolver.new(target, resolved_type, selections, query)
    resolver.result
  end
end
