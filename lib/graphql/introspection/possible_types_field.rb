GraphQL::Introspection::PossibleTypesField = GraphQL::Field.define do
  description "Types which compose this Union or Interface"
  type -> { types[!GraphQL::Introspection::TypeType] }
  resolve -> (target, args, ctx) {
    if target.kind.resolves?
      ctx.schema.possible_types(target).sort_by(&:name)
    else
      nil
    end
  }
end
