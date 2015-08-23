module GraphQL
  class Query
    module SerialExecution
      class FragmentSpreadResolution
        attr_reader :ast_fragment_spread, :type, :target, :query, :ast_fragment, :resolved_type, :execution_strategy
        def initialize(ast_fragment_spread, type, target, query, execution_strategy)
          @ast_fragment_spread = ast_fragment_spread
          @type = type
          @target = target
          @query = query
          @execution_strategy = execution_strategy
          @ast_fragment = query.fragments[ast_fragment_spread.name]
          child_type = query.schema.types[ast_fragment.type]
          @resolved_type = GraphQL::Query::TypeResolver.new(target, child_type, type).type
        end

        def result
          return {} if resolved_type.nil?
          selections = ast_fragment.selections
          resolver = execution_strategy.selection_resolution.new(target, resolved_type, selections, query, execution_strategy)
          resolver.result
        end
      end
    end
  end
end
