GraphQL::ID_TYPE = GraphQL::ScalarType.define do
  name "ID"
  coerce_result -> (value) { value.to_s }
  coerce_input -> (value) {
    case value
    when String, Fixnum, Bignum
      value.to_s
    else
      nil
    end
  }
end
