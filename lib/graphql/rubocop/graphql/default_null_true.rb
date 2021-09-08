# frozen_string_literal: true
require "rubocop"

module GraphQL
  module Cop
    module GraphQL
      # Identify (and auto-correct) any field configuration which duplicates
      # the default `null: true` property.
      #
      # `null: true` is default because nullable fields can always be converted
      # to non-null fields (`null: false`) without a breaking change. (The opposite change, from `null: false`
      # to `null: true`, change.)
      #
      # @example
      #   # Both of these define `name: String` in GraphQL:
      #
      #   # bad
      #   field :name, String, null: true
      #
      #   # good
      #   field :name, String
      #
      class DefaultNullTrue < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector
        MSG = "`null: true` is the default and can be removed."

        def_node_matcher :field_config_with_null_true?, <<-Pattern
        (
          send nil? :field ... (hash $(pair (sym :null) (true)) ...)
        )
        Pattern

        def on_send(node)
          field_config_with_null_true?(node) do |null_config|
            add_offense(null_config) do |corrector|
              corrector.replace(node.source_range, node.source_range.source.sub(/,\s+null:\s+true/m, ""))
            end
          end
        end
      end
    end
  end
end
