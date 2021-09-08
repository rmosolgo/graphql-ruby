# frozen_string_literal: true
require "rubocop"

module GraphQL
  module Cop
    module GraphQL
      # Identify (and auto-correct) any argument configuration which duplicates
      # the default `required: true` property.
      #
      # `required: true` is default because required arguments can always be converted
      # to optional arguments (`required: false`) without a breaking change. (The opposite change, from `required: false`
      # to `required: true`, change.)
      #
      # @example
      #   # Both of these define `id: ID!` in GraphQL:
      #
      #   # bad
      #   argument :id, ID, required: true
      #
      #   # good
      #   argument :id, ID
      #
      class DefaultRequiredTrue < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector
        MSG = "`required: true` is the default and can be removed."

        def_node_matcher :argument_config_with_required_true?, <<-Pattern
        (
          send nil? :argument ... (hash $(pair (sym :required) (true)) ...)
        )
        Pattern

        def on_send(node)
          argument_config_with_required_true?(node) do |required_config|
            add_offense(required_config) do |corrector|
              corrector.replace(node.source_range, node.source_range.source.sub(/,\s+required:\s+true/m, ""))
            end
          end
        end
      end
    end
  end
end
