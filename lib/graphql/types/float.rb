# frozen_string_literal: true

module GraphQL
  module Types
    class Float < GraphQL::Schema::Scalar
      description "Represents signed double-precision fractional values as specified by [IEEE 754](https://en.wikipedia.org/wiki/IEEE_floating_point)."

      def self.coerce_input(value, _ctx)
        if value.is_a?(Numeric)
          value.to_f
        else
          raise GraphQL::CoercionError, "Float cannot represent non numeric value: #{value.inspect}"
        end
      end

      def self.coerce_result(value, _ctx)
        coerced_value = Float(value, exception: false)

        if coerced_value.nil? || !coerced_value.finite?
          raise GraphQL::CoercionError, "Float cannot represent non numeric value: #{value.inspect}"
        end

        coerced_value
      end

      default_scalar true
    end
  end
end
