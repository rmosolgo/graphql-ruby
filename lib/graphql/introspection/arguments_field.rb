GraphQL::Introspection::ArgumentsField = GraphQL::Field.define do
  type !GraphQL::ListType.new(of_type: !GraphQL::Introspection::InputValueType)
  resolve ->(obj, args, ctx) {
    ctx.warden.each_argument(obj).to_a
  }
end
