GraphQL::Introspection::PossibleTypesField = GraphQL::Field.define do
  description "Types which compose this Union or Interface"
  type -> { types[GraphQL::Introspection::TypeType] }
  resolve -> (target, a, c) { target.kind.resolves? ? target.possible_types : nil }
end
