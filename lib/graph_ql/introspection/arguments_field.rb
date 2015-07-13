GraphQL::Introspection::ArgumentsField = GraphQL::Field.new do |f|
  f.description "Arguments allowed to this object"
  f.type GraphQL::ListType.new(of_type: GraphQL::Introspection::InputValueType)
  f.resolve -> (target, a, c) { target.arguments.values }
end
