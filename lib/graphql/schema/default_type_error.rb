# frozen_string_literal: true
module GraphQL
  class Schema
    module DefaultTypeError
      def self.call(type_error, ctx)
        case type_error
        when GraphQL::InvalidNullError
          if !type_error.parent_error?
            ctx.errors << type_error
          end
        when GraphQL::UnresolvedTypeError
          raise type_error
        end
      end
    end
  end
end
