class GraphQL::Query::SelectionResolver
  attr_reader :result
  def initialize(target, type, selections, operation_resolver)
    @result = selections.reduce({}) do |memo, ast_field|
      resolver = GraphQL::Query::FieldResolver.new(ast_field, type, target, operation_resolver)
      memo[resolver.result_name] = resolver.result
      memo
    end
  end
end
