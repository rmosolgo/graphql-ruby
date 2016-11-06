module GraphQL
  class Query
    class SerialExecution
      module ValueResolution
        def self.resolve(parent_type, field_defn, field_type, value, irep_nodes, query)
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
              field_type.coerce_result(value, query.warden)
            when GraphQL::TypeKinds::LIST
              wrapped_type = field_type.of_type
              result = value.each_with_index.map do |inner_value, index|
                query.context.path.push(index)
                inner_result = resolve(
                  parent_type,
                  field_defn,
                  wrapped_type,
                  inner_value,
                  irep_nodes,
                  query,
                )
                query.context.path.pop
                inner_result
              end
              result
            when GraphQL::TypeKinds::NON_NULL
              wrapped_type = field_type.of_type
              resolve(
                parent_type,
                field_defn,
                wrapped_type,
                value,
                irep_nodes,
                query,
              )
            when GraphQL::TypeKinds::OBJECT
              query.context.execution_strategy.selection_resolution.resolve(
                value,
                field_type,
                irep_nodes,
                query
              )
            when GraphQL::TypeKinds::UNION, GraphQL::TypeKinds::INTERFACE
              resolved_type = query.resolve_type(value)
              possible_types = query.possible_types(field_type)

              if !possible_types.include?(resolved_type)
                raise GraphQL::UnresolvedTypeError.new(irep_nodes.first.definition_name, field_type, parent_type, resolved_type, possible_types)
              else
                resolve(
                  parent_type,
                  field_defn,
                  resolved_type,
                  value,
                  irep_nodes,
                  query,
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
