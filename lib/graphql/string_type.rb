# frozen_string_literal: true
GraphQL::STRING_TYPE = GraphQL::ScalarType.define do
  name "String"
  description "Represents textual data as UTF-8 character sequences. This type is most often used by GraphQL to represent free-form human-readable text."

  coerce_result ->(value, ctx) {
    str = value.to_s
    if str.encoding == Encoding::US_ASCII || str.encoding == Encoding::UTF_8
      str
    else
      err = GraphQL::StringEncodingError.new(str)
      ctx.schema.type_error(err, ctx)
      nil
    end
  }

  coerce_input ->(value, _ctx) { value.is_a?(String) ? value : nil }
  default_scalar true
end
