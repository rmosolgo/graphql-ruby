GraphQL::Introspection::ArgumentsField = GraphQL::Field.define do
  description "Arguments allowed to this object"
  type GraphQL::ListType.new(of_type: GraphQL::Introspection::InputValueType)
  resolve -> (target, a, c) { target.arguments.values }
end
