module GraphQL
  class Query
    class SerialExecution
      module OperationResolution
        def self.resolve(irep_node, target, query)
          query.context.execution_strategy.selection_resolution.resolve(
            query.root_value,
            target,
            [irep_node],
            query
          )
        rescue GraphQL::InvalidNullError => err
          err.parent_error? || query.context.errors.push(err)
          nil
        end
      end
    end
  end
end
