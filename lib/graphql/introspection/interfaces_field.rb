# frozen_string_literal: true
GraphQL::Introspection::InterfacesField = GraphQL::Field.define do
  type -> { types[!GraphQL::Introspection::TypeType] }
  resolve ->(target, a, ctx) {
    if target.kind == GraphQL::TypeKinds::OBJECT
      ctx.warden.interfaces(target)
    else
      nil
    end
  }
end
