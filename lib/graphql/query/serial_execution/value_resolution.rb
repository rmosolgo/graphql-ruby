module GraphQL
  class Query
    class SerialExecution
      module ValueResolution
        def self.resolve(parent_type, field_defn, field_type, value, irep_node, execution_context)
          if value.nil? || value.is_a?(GraphQL::ExecutionError)
            if field_type.kind.non_null?
              raise GraphQL::InvalidNullError.new(parent_type.name, field_defn.name, value)
            else
              nil
            end
          else
            case field_type.kind
            when GraphQL::TypeKinds::SCALAR
              field_type.coerce_result(value)
            when GraphQL::TypeKinds::ENUM
              field_type.coerce_result(value, execution_context.query.warden)
            when GraphQL::TypeKinds::LIST
              wrapped_type = field_type.of_type
              result = value.each_with_index.map do |inner_value, index|
                irep_node.index = index
                resolve(
                  parent_type,
                  field_defn,
                  wrapped_type,
                  inner_value,
                  irep_node,
                  execution_context,
                )
              end
              irep_node.index = nil
              result
            when GraphQL::TypeKinds::NON_NULL
              wrapped_type = field_type.of_type
              resolve(
                parent_type,
                field_defn,
                wrapped_type,
                value,
                irep_node,
                execution_context,
              )
            when GraphQL::TypeKinds::OBJECT
              execution_context.strategy.selection_resolution.resolve(
                value,
                field_type,
                irep_node,
                execution_context
              )
            when GraphQL::TypeKinds::UNION, GraphQL::TypeKinds::INTERFACE
              resolved_type = execution_context.schema.resolve_type(value, execution_context.query.context)
              possible_types = execution_context.possible_types(field_type)

              if !possible_types.include?(resolved_type)
                raise GraphQL::UnresolvedTypeError.new(irep_node.definition_name, field_type, parent_type, resolved_type, possible_types)
              else
                resolve(
                  parent_type,
                  field_defn,
                  resolved_type,
                  value,
                  irep_node,
                  execution_context,
                )
              end
            else
              raise("Unknown type kind: #{field_type.kind}")
            end
          end
        end
      end
    end
  end
end
