GraphQL::Introspection::SchemaType = GraphQL::ObjectType.new do |t, type|
  t.name "__Schema"
  t.description "A GraphQL schema"
  t.fields({
    types: GraphQL::Field.new { |f|
      f.type !type[!GraphQL::Introspection::TypeType]
      f.description "Types in this schema"
      f.resolve -> (obj, arg, ctx) { obj.types.values }
    },
    directives: GraphQL::Field.new { |f|
      f.type !type[!GraphQL::Introspection::DirectiveType]
      f.description "Directives in this schema"
      f.resolve -> (obj, arg, ctx) { obj.directives.values }
    },
    queryType: GraphQL::Field.new { |f|
      f.type !GraphQL::Introspection::TypeType
      f.description "The query root of this schema"
      f.resolve -> (obj, arg, ctx) { obj.query }
    },
    mutationType: GraphQL::Field.new { |f|
      f.type GraphQL::Introspection::TypeType
      f.description "The mutation root of this schema"
      f.resolve -> (obj, arg, ctx) { obj.mutation }
    },
  })
end
