GraphQL::Introspection::OfTypeField = GraphQL::Field.define do
  name "ofType"
  description "The modified type of this type"
  type -> { GraphQL::Introspection::TypeType }
  resolve -> (obj, args, ctx) { obj.kind.wraps? ? obj.of_type : nil }
end
