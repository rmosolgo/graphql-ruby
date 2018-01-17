# frozen_string_literal: true
module GraphQL
  module Introspection
    class DirectiveType < Introspection::BaseObject
      graphql_name "__Directive"
      description "A Directive provides a way to describe alternate runtime execution and type validation behavior in a GraphQL document."\
                  "\n\n"\
                  "In some cases, you need to provide options to alter GraphQL's execution behavior "\
                  "in ways field arguments will not suffice, such as conditionally including or "\
                  "skipping a field. Directives provide this by describing additional information "\
                    "to the executor."
      field :name, String, null: false
      field :description, String, null: true
      field :locations, [GraphQL::Schema::LateBoundType.new("__DirectiveLocation")], null: false
      field :args, [GraphQL::Schema::LateBoundType.new("__InputValue")], null: false
      field :on_operation, Boolean, null: false, deprecation_reason: "Use `locations`.", method: :on_operation?
      field :on_fragment, Boolean, null: false, deprecation_reason: "Use `locations`.", method: :on_fragment?
      field :on_field, Boolean, null: false, deprecation_reason: "Use `locations`.", method: :on_field?

      def args
        @context.warden.arguments(@object)
      end
    end
  end
end
