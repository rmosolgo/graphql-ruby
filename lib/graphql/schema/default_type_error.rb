# frozen_string_literal: true
module GraphQL
  class Schema
    module DefaultTypeError
      def self.call(type_error, ctx)
        case type_error
        when GraphQL::InvalidNullError
          ctx.errors << type_error
        when GraphQL::UnresolvedTypeError, GraphQL::StringEncodingError, GraphQL::IntegerEncodingError
          raise type_error
        when GraphQL::IntegerDecodingError
          nil
        end
      end
    end
  end
end
