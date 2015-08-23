class GraphQL::Query::OperationResolver
  attr_reader :query, :target, :ast_operation_definition

  def initialize(ast_operation_definition, target, query)
    @ast_operation_definition = ast_operation_definition
    @query = query
    @target = target
  end

  def result
    selections = ast_operation_definition.selections
    resolver = GraphQL::Query::SelectionResolver.new(nil, target, selections, query)
    resolver.result
  end
end
