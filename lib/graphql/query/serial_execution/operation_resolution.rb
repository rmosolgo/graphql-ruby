# frozen_string_literal: true
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
        end
      end
    end
  end
end
