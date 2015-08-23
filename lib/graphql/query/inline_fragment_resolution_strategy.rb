class GraphQL::Query::InlineFragmentResolutionStrategy
  attr_reader :ast_inline_fragment, :type, :target, :query, :resolved_type
  def initialize(ast_inline_fragment, type, target, query)
    @ast_inline_fragment = ast_inline_fragment
    @type = type
    @target = target
    @query = query
    child_type = query.schema.types[ast_inline_fragment.type]
    @resolved_type = GraphQL::Query::TypeResolver.new(target, child_type, type).type
  end

  def result
    return {} if resolved_type.nil?
    selections = ast_inline_fragment.selections
    resolver = GraphQL::Query::SelectionResolver.new(target, resolved_type, selections, query)
    resolver.result
  end
end
