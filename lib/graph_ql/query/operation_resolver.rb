class GraphQL::Query::OperationResolver
  extend GraphQL::Forwardable
  attr_reader :variables, :query

  def initialize(operation_definition, query)
    @operation_definition = operation_definition
    @variables = query.params
    @query = query
  end

  delegate :context, to: :query

  def result
    @result ||= execute(@operation_definition, query)
  end

  private

  def execute(op_def, query)
    root = if op_def.operation_type == "query"
      query.schema.query
    elsif op_def.operation_type == "mutation"
      query.schema.mutation
    end
    resolver = GraphQL::Query::SelectionResolver.new(nil, root, op_def.selections, self)
    resolver.result
  end
end
