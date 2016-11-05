module GraphQL
  class Query
    class SerialExecution
      module SelectionResolution
        def self.resolve(target, current_type, irep_node, execution_context)
          selection_result = {}
          irep_node.typed_children.each do |type_defn, typed_children|
            if GraphQL::Execution::Typecast.compatible?(current_type, type_defn, execution_context.query.context)
              typed_children.each do |name, irep_node|
                if irep_node.included?
                  previous_result = selection_result.fetch(irep_node.name, :__graphql_not_resolved__)
                  case previous_result
                  when :__graphql_not_resolved__
                    # There's no value for this yet, so we can assign it directly
                    field_result = execution_context.strategy.field_resolution.new(
                      irep_node,
                      current_type,
                      target,
                      execution_context
                    ).result
                    selection_result.merge!(field_result)
                  when Hash
                    # This field was also requested on a different type, so we need
                    # to deeply merge _this_ branch with the other branch
                    field_result = execution_context.strategy.field_resolution.new(
                      irep_node,
                      current_type,
                      target,
                      execution_context
                    ).result
                    GraphQL::Execution::MergeBranchResult.merge(selection_result, field_result)
                  else
                    # This value has already been resolved in another type branch
                  end
                end
              end
            end
          end
          selection_result
        end
      end
    end
  end
end
