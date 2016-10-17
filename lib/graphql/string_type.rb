GraphQL::STRING_TYPE = GraphQL::ScalarType.define do
  name "String"
  description "Represents textual data as UTF-8 character sequences. This type is most often used by GraphQL to represent free-form human-readable text."

  coerce_result ->(value) { value.to_s }
  coerce_input ->(value) { value.is_a?(String) ? value : nil }
end
