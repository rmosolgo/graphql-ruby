GraphQL::Introspection::SchemaType = GraphQL::ObjectType.define do
  name "__Schema"
  description "A GraphQL schema"

  field :types, !types[!GraphQL::Introspection::TypeType], "Types in this schema" do
    resolve -> (obj, arg, ctx) { obj.types.values.sort_by(&:name) }
  end

  field :directives, !types[!GraphQL::Introspection::DirectiveType], "Directives in this schema" do
    resolve -> (obj, arg, ctx) { obj.directives.values.sort_by(&:name) }
  end

  field :queryType, !GraphQL::Introspection::TypeType, "The query root of this schema" do
    resolve -> (obj, arg, ctx) { obj.query }
  end

  field :mutationType, GraphQL::Introspection::TypeType, "The mutation root of this schema" do
    resolve -> (obj, arg, ctx) { obj.mutation }
  end

  field :subscriptionType, GraphQL::Introspection::TypeType, "The subscription root of this schema" do
    resolve -> (obj, arg, ctx) { obj.subscription }
  end
end
