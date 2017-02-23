# frozen_string_literal: true
GraphQL::STRING_TYPE = GraphQL::ScalarType.define do
  name "String"
  description "Represents textual data as UTF-8 character sequences. This type is most often used by GraphQL to represent free-form human-readable text."

  coerce_result ->(value) {
    str = value.to_s
    str.encoding == Encoding::US_ASCII || str.encoding == Encoding::UTF_8 ? str : nil
  }

  coerce_input ->(value) { value.is_a?(String) ? value : nil }
  default_scalar true
end
