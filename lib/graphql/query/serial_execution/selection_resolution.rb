module GraphQL
  class Query
    class SerialExecution
      module SelectionResolution
        def self.resolve(target, current_type, irep_nodes, query_ctx)
          own_selections = query_ctx.query.selections(irep_nodes, current_type)

          selection_result = {}

          own_selections.each do |name, child_irep_nodes|
            selection_result.merge!(query_ctx.execution_strategy.field_resolution.new(
              child_irep_nodes,
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
