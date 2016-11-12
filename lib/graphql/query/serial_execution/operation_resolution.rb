module GraphQL
  class Query
    class SerialExecution
      module OperationResolution
        def self.resolve(selection, target, query)
          result = query.context.execution_strategy.selection_resolution.resolve(
            query.root_value,
            target,
            selection,
            query.context,
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
