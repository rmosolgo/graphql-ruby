# frozen_string_literal: true
# typed: true
module GraphQL
  module StaticValidation
    # @requires_ancestor: GraphQL::StaticValidation::BaseVisitor
    module FragmentsAreNamed
      def on_fragment_definition(node, _parent)
        if node.name.nil?
          add_error(GraphQL::StaticValidation::FragmentsAreNamedError.new(
            "Fragment definition has no name",
            nodes: node
          ))
        end
        super
      end
    end
  end
end
