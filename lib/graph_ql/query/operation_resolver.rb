class GraphQL::Query::OperationResolver
  def initialize(operation_definition, query)
    @operation_definition = operation_definition
    @query = query
    @root = query.schema.query
  end

  def response
    @response ||= execute
  end

  private

  def execute
    resolver = GraphQL::Query::SelectionResolver.new(nil, @root, @operation_definition.selections, @query)
    resolver.result
  end
end
