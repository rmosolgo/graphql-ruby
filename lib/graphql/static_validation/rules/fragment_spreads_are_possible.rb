# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  module StaticValidation
    #--
    # @requires_ancestor: GraphQL::StaticValidation::BaseVisitor
    # @requires_ancestor: GraphQL::StaticValidation::BaseVisitor::ContextMethods
    module FragmentSpreadsArePossible
      #: (GraphQL::Language::Nodes::Document document, GraphQL::StaticValidation::ValidationContext context) -> void
      def initialize(document, context)
        super
        @spreads_to_validate = [] #: Array[FragmentSpread]
      end

      #: (GraphQL::Language::Nodes::InlineFragment node, GraphQL::Language::Nodes::AbstractNode? parent) -> void
      def on_inline_fragment(node, parent)
        fragment_parent = parent_type_definition
        fragment_child = type_definition
        if fragment_child
          validate_fragment_in_scope(fragment_parent, fragment_child, node, context, context.path)
        end
        super
      end

      #: (GraphQL::Language::Nodes::FragmentSpread node, GraphQL::Language::Nodes::AbstractNode? parent) -> void
      def on_fragment_spread(node, parent)
        fragment_parent = type_definition
        @spreads_to_validate << FragmentSpread.new(node: node, parent_type: fragment_parent, path: context.path)
        super
      end

      #: (GraphQL::Language::Nodes::Document node, GraphQL::Language::Nodes::AbstractNode? parent) -> void
      def on_document(node, parent)
        super
        @spreads_to_validate.each do |frag_spread|
          frag_node = context.fragments[frag_spread.node.name]
          if frag_node
            fragment_child_name = frag_node.type.name
            fragment_child = types.type(fragment_child_name)
            # Might be non-existent type name
            if fragment_child
              validate_fragment_in_scope(frag_spread.parent_type, fragment_child, frag_spread.node, context, frag_spread.path)
            end
          end
        end
      end

      private

      #: (GraphQL::Schema::Member::type_definition? parent_type, GraphQL::Schema::Member::type_definition child_type, GraphQL::Language::Nodes::InlineFragment | GraphQL::Language::Nodes::FragmentSpread node, GraphQL::StaticValidation::ValidationContext context, Array[String | Integer] path) -> void
      def validate_fragment_in_scope(parent_type, child_type, node, context, path)
        if !child_type.kind.fields?
          # It's not a valid fragment type, this error was handled someplace else
          return
        end
        # This is nil inside a field that doesn't exist. Other rules halt validation in that case.
        parent_type = parent_type #: as !nil
        parent_types = types.possible_types(parent_type.unwrap)
        child_types = types.possible_types(child_type.unwrap)

        if child_types.none? { |c| parent_types.include?(c) }
          name = node.is_a?(GraphQL::Language::Nodes::FragmentSpread) ? " #{node.name}" : ""
          add_error(GraphQL::StaticValidation::FragmentSpreadsArePossibleError.new(
            "Fragment#{name} on #{child_type.graphql_name} can't be spread inside #{parent_type.graphql_name}",
            nodes: node,
            path: path,
            fragment_name: name.empty? ? "unknown" : name,
            type: child_type.graphql_name,
            parent: parent_type.graphql_name
          ))
        end
      end

      class FragmentSpread
        #: GraphQL::Language::Nodes::FragmentSpread
        attr_reader :node
        #: GraphQL::Schema::Member::type_definition?
        attr_reader :parent_type
        #: Array[String | Integer]
        attr_reader :path

        #: (node: GraphQL::Language::Nodes::FragmentSpread, parent_type: GraphQL::Schema::Member::type_definition?, path: Array[String | Integer]) -> void
        def initialize(node:, parent_type:, path:)
          @node = node #: GraphQL::Language::Nodes::FragmentSpread
          @parent_type = parent_type #: GraphQL::Schema::Member::type_definition?
          @path = path #: Array[String | Integer]
        end
      end
    end
  end
end
