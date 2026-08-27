# frozen_string_literal: true

module GraphQL
  module Types
    class Float < GraphQL::Schema::Scalar
      description "Represents signed double-precision fractional values as specified by [IEEE 754](https://en.wikipedia.org/wiki/IEEE_floating_point)."

      def self.coerce_input(value, ctx)
        return if !value.is_a?(Numeric)

        value = value.to_f
        if value.finite?
          value
        else
          err = GraphQL::FloatDecodingError.new(value)
          ctx.schema.type_error(err, ctx)
        end
      end

      def self.coerce_result(value, ctx)
        value = value.to_f
        if value.finite?
          value
        else
          err = GraphQL::FloatEncodingError.new(value, context: ctx)
          ctx.schema.type_error(err, ctx)
        end
      end

      default_scalar true
    end
  end
end
