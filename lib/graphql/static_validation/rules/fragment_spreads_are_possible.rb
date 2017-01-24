# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class FragmentSpreadsArePossible
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)

        context.visitor[GraphQL::Language::Nodes::InlineFragment] << ->(node, parent) {
          fragment_parent = context.object_types[-2]
          fragment_child = context.object_types.last
          if fragment_child
            validate_fragment_in_scope(fragment_parent, fragment_child, node, context)
          end
        }

        spreads_to_validate = []

        context.visitor[GraphQL::Language::Nodes::FragmentSpread] << ->(node, parent) {
          fragment_parent = context.object_types.last
          spreads_to_validate << FragmentSpread.new(node: node, parent_type: fragment_parent)
        }

        context.visitor[GraphQL::Language::Nodes::Document].leave << ->(doc_node, parent) {
          spreads_to_validate.each do |frag_spread|
            fragment_child_name = context.fragments[frag_spread.node.name].type.name
            fragment_child = context.warden.get_type(fragment_child_name)
            # Might be non-existent type name
            if fragment_child
              validate_fragment_in_scope(frag_spread.parent_type, fragment_child, frag_spread.node, context)
            end
          end
        }
      end

      private

      def validate_fragment_in_scope(parent_type, child_type, node, context)
        if !child_type.kind.fields?
          # It's not a valid fragment type, this error was handled someplace else
          return
        end
        intersecting_types = context.warden.possible_types(parent_type.unwrap) & context.warden.possible_types(child_type.unwrap)
        if intersecting_types.none?
          name = node.respond_to?(:name) ? " #{node.name}" : ""
          context.errors << message("Fragment#{name} on #{child_type.name} can't be spread inside #{parent_type.name}", node)
        end
      end

      class FragmentSpread
        extend Forwardable
        attr_reader :node, :parent_type
        def initialize(node:, parent_type:)
          @node = node
          @parent_type = parent_type
        end
      end
    end
  end
end
