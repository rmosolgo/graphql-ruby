module GraphQL
  class Query
    class SerialExecution
      module OperationResolution
        def self.resolve(irep_node, current_type, query)
          result = query.context.execution_strategy.selection_resolution.resolve(
            query.root_value,
            current_type,
            [irep_node],
            query.context,
            mutation: query.mutation?
          )

          result
        rescue GraphQL::InvalidNullError => err
          err.parent_error? || query.context.errors.push(err)
          nil
        end
      end
    end
  end
end
