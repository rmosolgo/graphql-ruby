# frozen_string_literal: true
module GraphQL
  class Schema
    module DefaultTypeError
      def self.call(value, field, parent_type, query_ctx)
        if field.type.kind.non_null?
          if value.nil?
            query_ctx.errors << GraphQL::InvalidNullError.new(parent_type.name, field.name, value)
          else
            # it was caused by GraphQL::ExecutionError
          end
        else
          resolved_type = query_ctx.query.resolve_type(value)
          possible_types = query_ctx.query.possible_types(field.type.unwrap)
          raise GraphQL::UnresolvedTypeError.new(field.name, field.type, parent_type, resolved_type, possible_types)
        end
      end
    end
  end
end
