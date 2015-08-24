module GraphQL
  class Query
    class SerialExecution
      class SelectionResolution
        attr_reader :target, :type, :selections, :query, :execution_strategy

        RESOLUTION_STRATEGIES = {
          GraphQL::Language::Nodes::Field =>          :field_resolution,
          GraphQL::Language::Nodes::FragmentSpread => :fragment_spread_resolution,
          GraphQL::Language::Nodes::InlineFragment => :inline_fragment_resolution,
        }

        def initialize(target, type, selections, query, execution_strategy)
          @target = target
          @type = type
          @selections = selections
          @query = query
          @execution_strategy = execution_strategy
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
            strategy_name = RESOLUTION_STRATEGIES[ast_field.class]
            strategy_class = execution_strategy.public_send(strategy_name)
            strategy = strategy_class.new(ast_field, type, target, query, execution_strategy)
            strategy.result
          }
          chain.result
        end
      end
    end
  end
end
