# frozen_string_literal: true
module GraphQL
  class Schema
    module DefaultTypeError
      def self.call(type_error, ctx)
        case type_error
        when GraphQL::InvalidNullError
          ctx.errors << type_error
        when GraphQL::UnresolvedTypeError, GraphQL::StringEncodingError
          raise type_error
        end
      end
    end
  end
end
