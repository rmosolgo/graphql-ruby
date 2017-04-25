# frozen_string_literal: true
GraphQL::STRING_TYPE = GraphQL::ScalarType.define do
  name "String"
  description "Represents textual data as UTF-8 character sequences. This type is most often used by GraphQL to represent free-form human-readable text."

  coerce_result ->(value, ctx) {
    begin
      str = value.to_s
      str.encoding == Encoding::UTF_8 ? str : str.encode(Encoding::UTF_8)
    rescue EncodingError
      err = GraphQL::StringEncodingError.new(str)
      ctx.schema.type_error(err, ctx)
    end
  }

  coerce_input ->(value, _ctx) { value.is_a?(String) ? value : nil }
  default_scalar true
end
