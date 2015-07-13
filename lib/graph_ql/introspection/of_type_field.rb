GraphQL::Introspection::OfTypeField = GraphQL::Field.new do |f|
  f.name "ofType"
  f.description "The modified type of this type"
  f.type -> { GraphQL::Introspection::TypeType }
  f.resolve -> (obj, args, ctx) {
    if obj.kind.wraps?
      obj.of_type
    else
      nil
    end
  }
end
