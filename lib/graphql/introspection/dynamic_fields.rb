# frozen_string_literal: true
module GraphQL
  module Introspection
    class DynamicFields < GraphQL::Schema::Object
      field :__typename, String, "The name of this type", null: false
      def __typename(field_ctx:)
        # TODO how to get the irep_node?
        # - Add something to the `field` signature, like
        #   extra: [:irep_node, :ast_node]
        # - Auto-detect extra args in the method signature?
        # - Add something to dynamic resolve, where it uses a class?
        irep_node = ??
        irep_node.owner_type
      end
    end
  end
end
