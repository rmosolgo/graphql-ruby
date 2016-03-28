GraphQL::Introspection::DirectiveType = GraphQL::ObjectType.define do
  name "__Directive"
  description "A query directive in this schema"
  field :name, !types.String, "The name of this directive"
  field :description, types.String, "The description for this type"
  field :args, field: GraphQL::Introspection::ArgumentsField
  field :locations, !types[!GraphQL::Introspection::DirectiveLocationEnum]
end
