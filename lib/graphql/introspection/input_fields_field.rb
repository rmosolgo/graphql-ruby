# frozen_string_literal: true
GraphQL::Introspection::InputFieldsField = GraphQL::Field.define do
  name "inputFields"
  introspection true
  type types[!GraphQL::Introspection::InputValueType]
  resolve ->(target, a, ctx) {
    if target.kind.input_object?
      ctx.warden.arguments(target)
    else
      nil
    end
  }
end
