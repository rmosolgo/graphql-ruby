# frozen_string_literal: true
# typed: strict
module GraphQL
  module StaticValidation
    #--
    # @requires_ancestor: GraphQL::StaticValidation::BaseVisitor
    module FragmentNamesAreUnique
      #: (GraphQL::Language::Nodes::Document document, GraphQL::StaticValidation::ValidationContext context) -> void
      def initialize(document, context)
        super
        @fragments_by_name = Hash.new { |h, k| h[k] = [] } #: Hash[String, Array[GraphQL::Language::Nodes::FragmentDefinition]]
      end

      #: (GraphQL::Language::Nodes::FragmentDefinition node, GraphQL::Language::Nodes::AbstractNode? parent) -> void
      def on_fragment_definition(node, parent)
        # The default proc creates the Array:
        fragments = @fragments_by_name[node.name] #: as !nil
        fragments << node
        super
      end

      #: (GraphQL::Language::Nodes::Document _n, GraphQL::Language::Nodes::AbstractNode? _p) -> void
      def on_document(_n, _p)
        super
        @fragments_by_name.each do |name, fragments|
          if fragments.length > 1
            add_error(GraphQL::StaticValidation::FragmentNamesAreUniqueError.new(
              %|Fragment name "#{name}" must be unique|,
              nodes: fragments,
              name: name
            ))
          end
        end
      end
    end
  end
end
