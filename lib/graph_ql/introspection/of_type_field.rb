GraphQL::OfTypeField = GraphQL::Field.new do |f|
  f.name 'ofType'
  f.description 'The modified type of this type'
  f.type -> { GraphQL::TypeType }
  f.resolve lambda  { |obj, _args, _ctx|
    if [GraphQL::TypeKinds::LIST, GraphQL::TypeKinds::NON_NULL].include?(obj.kind)
      obj.of_type
    end
  }
end
