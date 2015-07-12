GraphQL::PossibleTypesField = GraphQL::Field.new do |f|
  POSSIBLE_TYPE_KINDS = [GraphQL::TypeKinds::UNION, GraphQL::TypeKinds::INTERFACE]
  f.description 'Types which compose this Union or Interface'
  f.type -> { GraphQL::ListType.new(of_type: GraphQL::TypeType) }
  f.resolve lambda  { |target, _a, _c|
    target.possible_types if POSSIBLE_TYPE_KINDS.include?(target.kind)
  }
end
