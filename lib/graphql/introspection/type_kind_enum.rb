# frozen_string_literal: true
GraphQL::Introspection::TypeKindEnum = GraphQL::EnumType.define do
  name "__TypeKind"
  description "An enum describing what kind of type a given `__Type` is."
  GraphQL::TypeKinds::TYPE_KINDS.each do |type_kind|
    value(type_kind.name, type_kind.description)
  end
  introspection true
end
