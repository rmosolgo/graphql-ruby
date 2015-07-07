class GraphQL::Query::OperationResolver
  extend GraphQL::Forwardable
  attr_reader :variables, :query

  def initialize(operation_definition, query)
    @operation_definition = operation_definition
    @variables = operation_definition.variables.reduce({}) { |memo, var| memo[var.name] = var.value; memo }
    @query = query
  end

  delegate :context, to: :query

  def result
    @result ||= execute
  end

  private

  def execute
    root = @query.schema.query
    resolver = GraphQL::Query::SelectionResolver.new(nil, root, @operation_definition.selections, self)
    resolver.result
  end
end
