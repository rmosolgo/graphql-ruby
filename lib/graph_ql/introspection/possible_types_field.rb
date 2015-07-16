GraphQL::Introspection::PossibleTypesField = GraphQL::Field.new do |f, type|
  f.description "Types which compose this Union or Interface"
  f.type -> { type[GraphQL::Introspection::TypeType] }
  f.resolve -> (target, a, c) { target.kind.resolves? ? target.possible_types : nil }
end
