GraphQL::SchemaType = GraphQL::ObjectType.new do
  name '__Schema'
  description 'A GraphQL schema'
  fields(types: GraphQL::Field.new do |f|
    f.type !type[!GraphQL::TypeType]
    f.description 'Types in this schema'
    f.resolve -> (obj, _arg, _ctx) { obj.types.values }
  end,
         directives: GraphQL::Field.new do |f|
           f.type !type[!GraphQL::DirectiveType]
           f.description 'Directives in this schema'
           f.resolve -> (obj, _arg, _ctx) { obj.directives.values }
         end,
         queryType: GraphQL::Field.new do |f|
           f.type !GraphQL::TypeType
           f.description 'The query root of this schema'
           f.resolve -> (obj, _arg, _ctx) { obj.query }
         end,
         mutationType: GraphQL::Field.new do |f|
           f.type GraphQL::TypeType
           f.description 'The mutation root of this schema'
           f.resolve -> (obj, _arg, _ctx) { obj.mutation }
         end)
end
# type __Schema {
#   types: [__Type!]!
#   queryType: __Type!
#   mutationType: __Type
#   directives: [__Directive!]!
# }
