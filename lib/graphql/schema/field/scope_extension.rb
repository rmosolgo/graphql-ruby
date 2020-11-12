# frozen_string_literal: true

module GraphQL
  class Schema
    class Field
      class ScopeExtension < GraphQL::Schema::FieldExtension
        def after_resolve(object:, arguments:, context:, value:, memo:)
          if value.nil?
            value
          else
            ret_type = @field.type.unwrap
            if ret_type.respond_to?(:scope_items)
              ret_type.scope_items(value, context)
            else
              value
            end
          end
        end
      end
    end
  end
end
