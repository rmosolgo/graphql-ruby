module GraphQL
  class Query
    class SerialExecution
      module OperationResolution
        def self.resolve(frame, root_type, execution_context)
          execution_context.strategy.selection_resolution.resolve(
            execution_context.query.root_value,
            root_type,
            frame,
            execution_context
          )
        rescue GraphQL::InvalidNullError => err
          err.parent_error? || execution_context.add_error(err)
          nil
        end
      end
    end
  end
end
