# frozen_string_literal: true
GraphQL::Introspection::PossibleTypesField = GraphQL::Field.define do
  type -> { types[!GraphQL::Introspection::TypeType] }
  resolve ->(target, args, ctx) {
    if target.kind.resolves?
      ctx.warden.possible_types(target)
    else
      nil
    end
  }
end
