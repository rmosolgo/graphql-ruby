module GraphQL
  class Query
    class SerialExecution
      module SelectionResolution
        def self.resolve(target, current_type, irep_nodes, query_ctx, mutation: false )

          own_selections = query_ctx.query.selections(irep_nodes, current_type)

          selection_result = {}

          own_selections.each do |name, child_irep_nodes|
            field_result = query_ctx.execution_strategy.field_resolution.new(
              child_irep_nodes,
              current_type,
              target,
              query_ctx
            ).result

            if mutation
              GraphQL::Execution::Boxed.unbox(field_result)
            end
            selection_result.merge!(field_result)
          end

          selection_result
        end
      end
    end
  end
end
