GraphQL::Introspection::DirectiveType = GraphQL::ObjectType.define do
  name "__Directive"
  description "A query directive in this schema"
  field :name, !types.String, "The name of this directive"
  field :description, types.String, "The description for this type"
  field :args, field: GraphQL::Introspection::ArgumentsField
  field :onOperation, !types.Boolean, "Does this directive apply to operations?", property: :on_operation?
  field :onFragment, !types.Boolean, "Does this directive apply to fragments?", property: :on_fragment?
  field :onField, !types.Boolean, "Does this directive apply to fields?", property: :on_field?
end
