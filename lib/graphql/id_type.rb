GraphQL::ID_TYPE = GraphQL::ScalarType.define do
  name "ID"
  description "Represents a unique identifier that is Base64 obfuscated. It is often used to refetch an object or as key for a cache. The ID type appears in a JSON response as a String; however, it is not intended to be human-readable. When expected as an input type, any string (such as `\"VXNlci0xMA==\"`) or integer (such as `4`) input value will be accepted as an ID."

  coerce_result ->(value) { value.to_s }
  coerce_input ->(value) {
    case value
    when String, Fixnum, Bignum
      value.to_s
    else
      nil
    end
  }
end
