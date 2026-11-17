# frozen_string_literal: true
#--
# typed: strict

module GraphQL
  module Types
    # See [Types::BigInt](rdoc-ref:Types::BigInt) for handling integers outside 32-bit range.
    class Int < GraphQL::Schema::Scalar
      description "Represents non-fractional signed whole numeric values. Int can represent values between -(2^31) and 2^31 - 1."

      MIN = -(1 << 31) #: Integer
      MAX = (1 << 31) - 1 #: Integer

      #: (untyped value, GraphQL::Query::Context ctx) -> untyped
      def self.coerce_input(value, ctx)
        return if !value.is_a?(Integer)

        if value >= MIN && value <= MAX
          value
        else
          err = GraphQL::IntegerDecodingError.new(value)
          ctx.schema.type_error(err, ctx)
        end
      end

      #: (untyped value, GraphQL::Query::Context ctx) -> untyped
      def self.coerce_result(value, ctx)
        value = value.to_i
        if value >= MIN && value <= MAX
          value
        else
          err = GraphQL::IntegerEncodingError.new(value, context: ctx)
          ctx.schema.type_error(err, ctx)
        end
      end

      default_scalar true
    end
  end
end
