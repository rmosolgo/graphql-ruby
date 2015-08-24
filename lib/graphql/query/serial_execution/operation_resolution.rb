module GraphQL
  class Query
    class SerialExecution
      class OperationResolution
        attr_reader :query, :target, :ast_operation_definition, :execution_strategy

        def initialize(ast_operation_definition, target, query, execution_strategy)
          @ast_operation_definition = ast_operation_definition
          @query = query
          @target = target
          @execution_strategy = execution_strategy
        end

        def result
          selections = ast_operation_definition.selections
          resolver = execution_strategy.selection_resolution.new(nil, target, selections, query, execution_strategy)
          resolver.result
        end
      end
    end
  end
end
