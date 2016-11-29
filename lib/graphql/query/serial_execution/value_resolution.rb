# frozen_string_literal: true
module GraphQL
  class Query
    class SerialExecution
      module ValueResolution
        def self.resolve(parent_type, field_defn, field_type, value, selection, query_ctx)
          case value
          when GraphQL::ExecutionError, NilClass
            if field_type.kind.non_null?
              query_ctx.schema.type_error(value, field_defn, parent_type, query_ctx)
              GraphQL::Execution::Execute::PROPAGATE_NULL
            else
              nil
            end
          when GraphQL::Execution::Execute::PROPAGATE_NULL
            value
          else
            case field_type.kind
            when GraphQL::TypeKinds::SCALAR
              field_type.coerce_result(value)
            when GraphQL::TypeKinds::ENUM
              field_type.coerce_result(value, query_ctx.query.warden)
            when GraphQL::TypeKinds::LIST
              wrapped_type = field_type.of_type
              result = value.each_with_index.map do |inner_value, index|
                inner_ctx = query_ctx.spawn(
                  key: index,
                  selection: selection,
                  parent_type: wrapped_type,
                  field: field_defn,
                )

                inner_result = resolve(
                  parent_type,
                  field_defn,
                  wrapped_type,
                  inner_value,
                  selection,
                  inner_ctx,
                )
                inner_result
              end
              result
            when GraphQL::TypeKinds::NON_NULL
              wrapped_type = field_type.of_type
              required_value = resolve(
                parent_type,
                field_defn,
                wrapped_type,
                value,
                selection,
                query_ctx,
              )
              if required_value.nil?
                GraphQL::Execution::Execute::PROPAGATE_NULL
              else
                required_value
              end
            when GraphQL::TypeKinds::OBJECT
              query_ctx.execution_strategy.selection_resolution.resolve(
                value,
                field_type,
                selection,
                query_ctx
              )
            when GraphQL::TypeKinds::UNION, GraphQL::TypeKinds::INTERFACE
              query = query_ctx.query
              resolved_type = query.resolve_type(value)
              possible_types = query.possible_types(field_type)

              if !possible_types.include?(resolved_type)
                query.schema.type_error(value, field_defn, parent_type, query_ctx)
                nil
              else
                resolve(
                  parent_type,
                  field_defn,
                  resolved_type,
                  value,
                  selection,
                  query_ctx,
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
