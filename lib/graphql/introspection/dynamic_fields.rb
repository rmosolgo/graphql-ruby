# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  module Introspection
    class DynamicFields < Introspection::BaseObject
      field :__typename, String, "The name of this type", null: false, dynamic_introspection: true, resolve_each: true

      #: -> ::String
      def __typename
        self.class.__typename(object, context)
      end

      #: (untyped object, GraphQL::Query::Context context) -> ::String
      def self.__typename(object, context)
        object.class.graphql_name
      end
    end
  end
end
