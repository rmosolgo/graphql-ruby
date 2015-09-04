module GraphQL
  class Query
    class BaseExecution
      class SelectedObjectResolution
        attr_reader :ast_node, :parent_type, :target, :query, :execution_strategy
        def initialize(ast_node, parent_type, target, query, execution_strategy)
          @ast_node = ast_node
          @parent_type = parent_type
          @target = target
          @query = query
          @execution_strategy = execution_strategy
        end
      end
    end
  end
end
