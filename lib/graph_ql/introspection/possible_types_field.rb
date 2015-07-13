GraphQL::Introspection::PossibleTypesField = GraphQL::Field.new do |f|
  f.description "Types which compose this Union or Interface"
  f.type -> { GraphQL::ListType.new(of_type: GraphQL::Introspection::TypeType) }
  f.resolve -> (target, a, c) {
    if target.kind.resolves?
      target.possible_types
    else
      nil
    end
  }
end
