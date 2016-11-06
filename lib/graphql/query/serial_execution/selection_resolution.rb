module GraphQL
  class Query
    class SerialExecution
      module SelectionResolution
        def self.resolve(target, current_type, irep_nodes, execution_context)
          all_selections = GraphQL::InternalRepresentation::Selections.build(execution_context.query, irep_nodes)
          own_selections = all_selections[current_type]

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
