module GraphQL
  class Query
    module SerialExecution
      class InlineFragmentResolution
        attr_reader :ast_inline_fragment, :type, :target, :query, :resolved_type, :execution_strategy
        def initialize(ast_inline_fragment, type, target, query, execution_strategy)
          @ast_inline_fragment = ast_inline_fragment
          @type = type
          @target = target
          @query = query
          @execution_strategy = execution_strategy
          child_type = query.schema.types[ast_inline_fragment.type]
          @resolved_type = GraphQL::Query::TypeResolver.new(target, child_type, type).type
        end

        def result
          return {} if resolved_type.nil?
          selections = ast_inline_fragment.selections
          resolver = execution_strategy.selection_resolution.new(target, resolved_type, selections, query, execution_strategy)
          resolver.result
        end
      end
    end
  end
end
