module GraphQL
  class Query
    class SerialExecution
      module SelectionResolution
        def self.resolve(target, current_type, selection, query_ctx)
          selection_result = {}

          selection.each_selection(type: current_type) do |name, subselection|
            field_result = query_ctx.execution_strategy.field_resolution.new(
              subselection,
              current_type,
              target,
              query_ctx
            ).result

            if field_result.values.any? { |v| v == GraphQL::Execution::Execute::PROPAGATE_NULL }
              selection_result = nil
              break
            else
              selection_result.merge!(field_result)
            end
          end

          selection_result
        end
      end
    end
  end
end
