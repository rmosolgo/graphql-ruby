# frozen_string_literal: true
module GraphQL
  module Introspection
    class DynamicFields < Introspection::BaseObject
      field :__typename, String, "The name of this type", null: false, extras: [:irep_node]

      # `irep_node:` will be nil for the interpreter, since there is no such thing
      def __typename(irep_node: nil)
        if context.interpreter?
          object.class.graphql_name
        else
          irep_node.owner_type.name
        end
      end
    end
  end
end
