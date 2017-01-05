# frozen_string_literal: true
GraphQL::Introspection::DirectiveType = GraphQL::ObjectType.define do
  name "__Directive"
  description "A Directive provides a way to describe alternate runtime execution and type validation behavior in a GraphQL document."\
              "\n\n"\
              "In some cases, you need to provide options to alter GraphQL's execution behavior "\
              "in ways field arguments will not suffice, such as conditionally including or "\
              "skipping a field. Directives provide this by describing additional information "\
              "to the executor."
  field :name, !types.String
  field :description, types.String
  field :locations, !types[!GraphQL::Introspection::DirectiveLocationEnum]
  field :args, field: GraphQL::Introspection::ArgumentsField
  field :onOperation, !types.Boolean, deprecation_reason: "Use `locations`.", property: :on_operation?
  field :onFragment, !types.Boolean, deprecation_reason: "Use `locations`.", property: :on_fragment?
  field :onField, !types.Boolean, deprecation_reason: "Use `locations`.", property: :on_field?
  introspection true
end
