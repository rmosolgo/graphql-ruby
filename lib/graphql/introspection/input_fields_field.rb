# frozen_string_literal: true
GraphQL::Introspection::InputFieldsField = GraphQL::Field.define do
  name "inputFields"
  type types[!GraphQL::Introspection::InputValueType]
  resolve ->(target, a, ctx) {
    if target.kind.input_object?
      ctx.warden.input_fields(target)
    else
      nil
    end
  }
end
