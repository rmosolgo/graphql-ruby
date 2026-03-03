# frozen_string_literal: true

module GraphQL
  class Schema
    class Field
      class ScopeExtension < GraphQL::Schema::FieldExtension
        def after_resolve(object:, arguments:, context:, value:, memo:)
          if object.is_a?(GraphQL::Schema::Object)
            scope_value(value, context, field.type.unwrap)
          else
            rt = field.type.unwrap
            value.map { |v| scope_value(v, context, rt) }
          end
        end

        private

        def scope_value(value, context, return_type)
          if value.nil?
            value
          else
            if return_type.respond_to?(:scope_items)
              scoped_items = return_type.scope_items(value, context)
              if !scoped_items.equal?(value) && !return_type.reauthorize_scoped_objects
                if (current_runtime_state = Fiber[:__graphql_runtime_info]) &&
                    (query_runtime_state = current_runtime_state[context.query])
                  query_runtime_state.was_authorized_by_scope_items = true
                end
              end
              scoped_items
            else
              value
            end
          end
        end
      end
    end
  end
end
