GraphQL::OfTypeField = GraphQL::Field.new do |f|
  f.name "ofType"
  f.description "The modified type of this type"
  f.type :replace_me_with_graphql_type_type # see TypeType
  f.resolve -> (obj, args, ctx) {
    if [GraphQL::TypeKinds::LIST, GraphQL::TypeKinds::NON_NULL].include?(obj.kind)
      obj.of_type
    else
      nil
    end
  }
end
