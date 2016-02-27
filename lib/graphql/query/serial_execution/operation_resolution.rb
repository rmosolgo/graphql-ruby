module GraphQL
  class Query
    class SerialExecution
      class OperationResolution
        attr_reader :query, :target, :ast_operation_definition, :execution_context

        def initialize(ast_operation_definition, target, execution_context)
          @ast_operation_definition = ast_operation_definition
          @target = target
          @execution_context = execution_context
        end

        def result
          selections = ast_operation_definition.selections
          execution_context.strategy.selection_resolution.new(
            nil,
            target,
            selections,
            execution_context
          ).result
        end
      end
    end
  end
end
