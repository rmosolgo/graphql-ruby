GraphQL::INT_TYPE = GraphQL::ScalarType.define do
  name "Int"
  description "Represents non-fractional signed whole numeric values. Int can represent values between -(2^31) and 2^31 - 1."

  coerce_input ->(value) { value.is_a?(Numeric) ? value.to_i : nil }
  coerce_result ->(value) { value.to_i }
end
