# frozen_string_literal: true
module GraphQL
  module Introspection
    class DynamicFields < Introspection::BaseObject
      field :__typename, String, "The name of this type", null: false, extras: [:irep_node]
      def __typename(irep_node:)
        irep_node.owner_type.name
      end
    end
  end
end
