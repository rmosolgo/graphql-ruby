module GraphQL
  module StaticValidation
    class FragmentSpreadsArePossible
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)

        context.visitor[GraphQL::Language::Nodes::InlineFragment] << ->(node, parent) {
          fragment_parent = context.object_types[-2]
          fragment_child = context.object_types.last
          if fragment_child
            validate_fragment_in_scope(fragment_parent, fragment_child, node, context, context.path)
          end
        }

        spreads_to_validate = []

        context.visitor[GraphQL::Language::Nodes::FragmentSpread] << ->(node, parent) {
          fragment_parent = context.object_types.last
          spreads_to_validate << FragmentSpread.new(node: node, parent_type: fragment_parent, path: context.path)
        }

        context.visitor[GraphQL::Language::Nodes::Document].leave << ->(doc_node, parent) {
          spreads_to_validate.each do |frag_spread|
            fragment_child_name = context.fragments[frag_spread.node.name].type
            fragment_child = context.schema.types.fetch(fragment_child_name, nil) # Might be non-existent type name
            if fragment_child
              validate_fragment_in_scope(frag_spread.parent_type, fragment_child, frag_spread.node, context, frag_spread.path)
            end
          end
        }
      end

      private

      def validate_fragment_in_scope(parent_type, child_type, node, context, path)
        if !child_type.kind.fields?
          # It's not a valid fragment type, this error was handled someplace else
          return
        end
        intersecting_types = get_possible_types(parent_type, context.schema) & get_possible_types(child_type, context.schema)
        if intersecting_types.none?
          name = node.respond_to?(:name) ? " #{node.name}" : ""
          context.errors << message("Fragment#{name} on #{child_type.name} can't be spread inside #{parent_type.name}", node, path: path)
        end
      end

      def get_possible_types(type, schema)
        if type.kind.wraps?
          get_possible_types(type.of_type, schema)
        elsif type.kind.object?
          [type]
        elsif type.kind.resolves?
          schema.possible_types(type)
        else
          []
        end
      end

      class FragmentSpread
        attr_reader :node, :parent_type, :path
        ### Ruby 1.9.3 unofficial support
        # def initialize(node:, parent_type:, path:)
        def initialize(options = {})
          node = options[:node]
          parent_type = options[:parent_type]
          path = options[:path]

          @node = node
          @parent_type = parent_type
          @path = path
        end
      end
    end
  end
end
