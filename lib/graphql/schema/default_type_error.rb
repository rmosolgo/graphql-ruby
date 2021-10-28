# frozen_string_literal: true
module GraphQL
  class Schema
    module DefaultTypeError
      def self.call(type_error, ctx)
        case type_error
        when GraphQL::InvalidNullError, GraphQL::IntegerDecodingError
          nil
        when GraphQL::UnresolvedTypeError, GraphQL::StringEncodingError, GraphQL::IntegerEncodingError
          raise type_error
        else
          # The library doesn't send any other errors this way...
          nil
        end
      end
    end
  end
end
