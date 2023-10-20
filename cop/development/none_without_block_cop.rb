# frozen_string_literal: true
require 'rubocop'

module Cop
  module Development
    # A custom Rubocop rule to catch uses of `.none?` without a block.
    #
    # @see https://github.com/rmosolgo/graphql-ruby/pull/2090
    class NoneWithoutBlockCop < RuboCop::Cop::Cop
      MSG = <<-MD
Instead of `.none?` without a block:

- Use `.empty?` to check for an empty collection (faster)
- Add a block to explicitly check for `false` (more clear)

Run `-a` to replace this with `.empty?`.
      MD
      def on_block(node)
        # Since this method was called with a block, it can't be
        # a case of `.none?` without a block
        ignore_node(node.send_node)
      end

      def on_send(node)
        if !ignored_node?(node) && node.method_name == :none? && node.arguments.size == 0
          add_offense(node)
        end
      end

      def autocorrect(node)
        lambda do |corrector|
          corrector.replace(node.location.selector, "empty?")
        end
      end
    end
  end
end
