module GraphQL
  class Query
    class SerialExecution
      class InlineFragmentResolution  < GraphQL::Query::BaseExecution::SelectedObjectResolution
        attr_reader :resolved_type
        def initialize(ast_node, type, target, query, execution_strategy)
          super
          child_type = query.schema.types[ast_node.type]
          @resolved_type = GraphQL::Query::TypeResolver.new(target, child_type, type).type
        end

        def result
          return {} if resolved_type.nil?
          selections = ast_node.selections
          resolver = execution_strategy.selection_resolution.new(target, resolved_type, selections, query, execution_strategy)
          resolver.result
        end
      end
    end
  end
end
