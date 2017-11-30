# frozen_string_literal: true
GraphQL::Introspection::ArgumentsField = GraphQL::Field.define do
  type !GraphQL::ListType.new(of_type: !GraphQL::Introspection::InputValueType)
  introspection true
  resolve ->(obj, args, ctx) {
    ctx.warden.arguments(obj)
  }
end
