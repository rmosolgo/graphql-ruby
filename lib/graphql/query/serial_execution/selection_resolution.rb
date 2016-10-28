module GraphQL
  class Query
    class SerialExecution
      module SelectionResolution
        def self.resolve(target, current_type, irep_node, execution_context)
          irep_node.children.each_with_object({}) do |(name, irep_node), memo|
            if irep_node.included? && irep_node.definitions.any? { |potential_type, field_defn| GraphQL::Execution::Typecast.compatible?(current_type, potential_type, execution_context.query.context) }
              field_result = execution_context.strategy.field_resolution.new(
                irep_node,
                current_type,
                target,
                execution_context
              ).result
              memo.merge!(field_result)
            end
          end
        end
      end
    end
  end
end
