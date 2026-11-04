# frozen_string_literal: true
# typed: strict
module GraphQL
  module StaticValidation
    #--
    # @requires_ancestor: GraphQL::StaticValidation::BaseVisitor
    module FragmentsAreFinite
      #: (GraphQL::Language::Nodes::Document _n, GraphQL::Language::Nodes::AbstractNode? _p) -> void
      def on_document(_n, _p)
        super
        dependency_map = context.dependencies
        dependency_map.cyclical_definitions.each do |defn|
          if defn.node.is_a?(GraphQL::Language::Nodes::FragmentDefinition)
            add_error(GraphQL::StaticValidation::FragmentsAreFiniteError.new(
              "Fragment #{defn.name} contains an infinite loop",
              nodes: defn.node,
              path: defn.path,
              name: defn.name
            ))
          end
        end
      end
    end
  end
end
