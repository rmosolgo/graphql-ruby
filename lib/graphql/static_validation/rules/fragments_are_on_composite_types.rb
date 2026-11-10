# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  module StaticValidation
    #--
    # @requires_ancestor: GraphQL::StaticValidation::BaseVisitor
    module FragmentsAreOnCompositeTypes
      #: (GraphQL::Language::Nodes::FragmentDefinition node, GraphQL::Language::Nodes::AbstractNode parent) -> void
      def on_fragment_definition(node, parent)
        validate_type_is_composite(node) && super
      end

      #: (GraphQL::Language::Nodes::InlineFragment node, GraphQL::Language::Nodes::AbstractNode parent) -> void
      def on_inline_fragment(node, parent)
        validate_type_is_composite(node) && super
      end

      private

      #: (GraphQL::Language::Nodes::FragmentDefinition | GraphQL::Language::Nodes::InlineFragment node) -> bool
      def validate_type_is_composite(node)
        node_type = node.type #: GraphQL::Language::Nodes::TypeName?
        if node_type.nil?
          # Inline fragment on the same type
          true
        else
          type_name = node_type.to_query_string
          type_def = types.type(type_name)
          if type_def.nil? || !type_def.kind.composite?
            add_error(GraphQL::StaticValidation::FragmentsAreOnCompositeTypesError.new(
              "Invalid fragment on type #{type_name} (must be Union, Interface or Object)",
              nodes: node,
              type: type_name
            ))
            false
          else
            true
          end
        end
      end
    end
  end
end
