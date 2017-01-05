# frozen_string_literal: true
GraphQL::BOOLEAN_TYPE = GraphQL::ScalarType.define do
  name "Boolean"
  description "Represents `true` or `false` values."

  coerce_input ->(value) { (value == true || value == false) ? value : nil }
  coerce_result ->(value) { !!value }
  default_scalar true
end
