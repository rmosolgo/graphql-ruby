# frozen_string_literal: true
module GraphQL
  class Query
    class SerialExecution
      module SelectionResolution
        def self.resolve(target, current_type, selection, query_ctx)
          selection_result = {}

          selection.typed_children[current_type].each do |name, subselection|
            selection_result.merge!(query_ctx.execution_strategy.field_resolution.new(
              subselection,
              current_type,
              target,
              query_ctx
            ).result)
          end

          selection_result
        end
      end
    end
  end
end
