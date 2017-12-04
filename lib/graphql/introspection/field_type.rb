# frozen_string_literal: true
module GraphQL
  module Introspection
    class FieldType < Introspection::BaseObject
      graphql_name "__Field"
      description "Object and Interface types are described by a list of Fields, each of which has "\
                  "a name, potentially a list of arguments, and a return type."
      field :name, String, null: false
      field :description, String, null: true
      field :args, [GraphQL::Schema::LateBoundType.new("__InputValue")], null: false
      field :type, GraphQL::Schema::LateBoundType.new("__Type"), null: false
      field :is_deprecated, Boolean, null: false
      field :deprecation_reason, String, null: true

      def is_deprecated
        !!@object.deprecation_reason
      end

      def args
        @context.warden.arguments(@object)
      end
    end
  end
end
