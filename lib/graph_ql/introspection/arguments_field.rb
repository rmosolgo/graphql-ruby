GraphQL::ArgumentsField = GraphQL::Field.new do |f|
  f.description 'Arguments allowed to this object'
  f.type GraphQL::ListType.new(of_type: GraphQL::InputValueType)
  f.resolve -> (target, _a, _c) { target.arguments.values }
end
