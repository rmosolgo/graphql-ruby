GraphQL::Introspection::ArgumentsField = GraphQL::Field.define do
  type !GraphQL::ListType.new(of_type: !GraphQL::Introspection::InputValueType)
  resolve ->(target, a, c) { target.arguments.values }
end
