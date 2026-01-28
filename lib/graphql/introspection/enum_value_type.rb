# frozen_string_literal: true
module GraphQL
  module Introspection
    class EnumValueType < Introspection::BaseObject
      graphql_name "__EnumValue"
      description "One possible value for a given Enum. Enum values are unique values, not a "\
                  "placeholder for a string or numeric value. However an Enum value is returned in "\
                  "a JSON response as a string."
      field :name, String, null: false, method: :graphql_name
      field :description, String
      field :is_deprecated, Boolean, null: false, resolve_each: :resolve_is_deprecated
      field :deprecation_reason, String

      def self.resolve_is_deprecated(object, context)
        !!object.deprecation_reason
      end
    end
  end
end
