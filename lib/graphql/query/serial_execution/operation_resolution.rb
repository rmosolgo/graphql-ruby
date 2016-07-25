module GraphQL
  class Query
    class SerialExecution
      class OperationResolution
        attr_reader :target, :execution_context, :irep_node

        def initialize(irep_node, target, execution_context)
          @target = target
          @irep_node = irep_node
          @execution_context = execution_context
        end

        def result
          execution_context.strategy.selection_resolution.new(
            execution_context.query.root_value,
            target,
            irep_node,
            execution_context
          ).result
        rescue GraphQL::InvalidNullError => err
          err.parent_error? || execution_context.add_error(err)
          nil
        end
      end
    end
  end
end
