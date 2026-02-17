# frozen_string_literal: true

module GraphQL
  module Types
    # @see {Types::BigInt} for handling integers outside 32-bit range.
    class Int < GraphQL::Schema::Scalar
      description "Represents non-fractional signed whole numeric values. Int can represent values between -(2^31) and 2^31 - 1."

      MIN = -(2**31)
      MAX = (2**31) - 1

      def self.coerce_input(value, ctx)
        return if !value.is_a?(Integer)

        if value >= MIN && value <= MAX
          value
        else
          err = GraphQL::IntegerDecodingError.new(value)
          ctx.schema.type_error(err, ctx)
        end
      end

      def self.coerce_result(value, ctx)
        value = Integer(value, exception: false)

        if value && (value >= MIN && value <= MAX)
          value
        else
          err = GraphQL::IntegerEncodingError.new(
            "Int cannot represent non 32-bit signed integer value: #{value.inspect}",
            value: value,
            context: ctx
          )
          ctx.schema.type_error(err, ctx)
        end
      end

      default_scalar true
    end
  end
end
