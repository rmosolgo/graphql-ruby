module GraphQL
  class Query
    class SerialExecution
      module SelectionResolution
        def self.resolve(target, current_type, irep_node, execution_context)
          selection_result = {}
          irep_node.typed_children.each do |type_defn, typed_children|
            type_child_result = {}
            compat = GraphQL::Execution::Typecast.compatible?(current_type, type_defn, execution_context.query.context)
            if compat
              typed_children.each do |name, irep_node|
                applies = irep_node.included? && irep_node.definitions.any? { |potential_type, field_defn| GraphQL::Execution::Typecast.compatible?(current_type, potential_type, execution_context.query.context) }
                if applies
                  field_result = execution_context.strategy.field_resolution.new(
                    irep_node,
                    current_type,
                    target,
                    execution_context
                  ).result
                  type_child_result.merge!(field_result)
                end
              end
            end
            deeply_merge(selection_result, type_child_result)
          end
          selection_result
        end

        def self.deeply_merge(complete_result, typed_result)
          typed_result.each do |key, value|
            if value.is_a?(Hash)
              (complete_result[key] ||= {}).merge!(value)
            else
              # TODO: we can avoid running this twice
              complete_result[key] = value
            end
          end
        end
      end
    end
  end
end
