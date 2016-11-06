module GraphQL
  class Query
    class SerialExecution
      module SelectionResolution
        def self.resolve(target, current_type, irep_nodes, execution_context)
          own_selections = execution_context.query.selections(irep_nodes, current_type)

          selection_result = {}

          own_selections.each do |name, child_irep_nodes|
            selection_result.merge!(execution_context.strategy.field_resolution.new(
              child_irep_nodes,
              current_type,
              target,
              execution_context
            ).result)
          end

          selection_result
        end
      end
    end
  end
end
