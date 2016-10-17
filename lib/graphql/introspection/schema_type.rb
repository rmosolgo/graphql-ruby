GraphQL::Introspection::SchemaType = GraphQL::ObjectType.define do
  name "__Schema"
  description "A GraphQL Schema defines the capabilities of a GraphQL server. It exposes all "\
              "available types and directives on the server, as well as the entry points for "\
              "query, mutation, and subscription operations."

  field :types, !types[!GraphQL::Introspection::TypeType], "A list of all types supported by this server." do
    resolve ->(obj, arg, ctx) { obj.types.values }
  end

  field :queryType, !GraphQL::Introspection::TypeType, "The type that query operations will be rooted at." do
    resolve ->(obj, arg, ctx) { obj.query }
  end

  field :mutationType, GraphQL::Introspection::TypeType, "If this server supports mutation, the type that mutation operations will be rooted at." do
    resolve ->(obj, arg, ctx) { obj.mutation }
  end

  field :subscriptionType, GraphQL::Introspection::TypeType, "If this server support subscription, the type that subscription operations will be rooted at." do
    resolve ->(obj, arg, ctx) { obj.subscription }
  end

  field :directives, !types[!GraphQL::Introspection::DirectiveType], "A list of all directives supported by this server." do
    resolve ->(obj, arg, ctx) { obj.directives.values }
  end
end
