class GraphQL::Query::SelectionResolver
  attr_reader :result
  def initialize(target, type, selections, query)
    @result = selections.reduce({}) do |memo, ast_field|
      p memo.keys.length, ast_field
      resolver = GraphQL::Query::FieldResolver.new(ast_field, type, target, query)
      memo[resolver.result_name] = resolver.result
      memo
    end
  end
end
