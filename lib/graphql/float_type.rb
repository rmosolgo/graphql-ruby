# frozen_string_literal: true
GraphQL::FLOAT_TYPE = GraphQL::ScalarType.define do
  name "Float"
  description "Represents signed double-precision fractional values as specified by [IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point)."

  coerce_input ->(value, _ctx) { value.is_a?(Numeric) ? value.to_f : nil }
  coerce_result ->(value, _ctx) { value.to_f }
  default_scalar true
end
