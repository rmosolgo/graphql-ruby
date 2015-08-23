class GraphQL::Query::SelectionResolver
  attr_reader :result

  RESOLUTION_STRATEGIES = {
    GraphQL::Language::Nodes::Field =>          GraphQL::Query::FieldResolutionStrategy,
    GraphQL::Language::Nodes::FragmentSpread => GraphQL::Query::FragmentSpreadResolutionStrategy,
    GraphQL::Language::Nodes::InlineFragment => GraphQL::Query::InlineFragmentResolutionStrategy,
  }

  def initialize(target, type, selections, query)
    @result = selections.reduce({}) do |memo, ast_field|
      chain = GraphQL::Query::DirectiveChain.new(ast_field, query) {
        strategy_class = RESOLUTION_STRATEGIES[ast_field.class]
        strategy = strategy_class.new(ast_field, type, target, query)
        strategy.result
      }
      memo.merge(chain.result)
    end
  end
end
