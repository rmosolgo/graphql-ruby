class GraphQL::Query::SelectionResolver
  attr_reader :target, :type, :selections, :query

  RESOLUTION_STRATEGIES = {
    GraphQL::Language::Nodes::Field =>          GraphQL::Query::FieldResolutionStrategy,
    GraphQL::Language::Nodes::FragmentSpread => GraphQL::Query::FragmentSpreadResolutionStrategy,
    GraphQL::Language::Nodes::InlineFragment => GraphQL::Query::InlineFragmentResolutionStrategy,
  }

  def initialize(target, type, selections, query)
    @target = target
    @type = type
    @selections = selections
    @query = query
  end

  def result
    selections.reduce({}) do |memo, ast_field|
      field_value = resolve_field(ast_field)
      memo.merge(field_value)
    end
  end

  private

  def resolve_field(ast_field)
    chain = GraphQL::Query::DirectiveChain.new(ast_field, query) {
      strategy_class = RESOLUTION_STRATEGIES[ast_field.class]
      strategy = strategy_class.new(ast_field, type, target, query)
      strategy.result
    }
    chain.result
  end
end
