# frozen_string_literal: true
GraphQL::Introspection::OfTypeField = GraphQL::Field.define do
  name "ofType"
  introspection true
  type -> { GraphQL::Introspection::TypeType }
  resolve ->(obj, args, ctx) { obj.kind.wraps? ? obj.of_type : nil }
end
