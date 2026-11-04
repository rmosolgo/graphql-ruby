# frozen_string_literal: true
# typed: strict
module GraphQL
  module StaticValidation
    #--
    # @requires_ancestor: GraphQL::StaticValidation::BaseVisitor
    module MutationRootExists
      #: (GraphQL::Language::Nodes::OperationDefinition node, GraphQL::Language::Nodes::AbstractNode? _parent) -> void
      def on_operation_definition(node, _parent)
        if node.operation_type == 'mutation' && context.types.mutation_root.nil?
          add_error(GraphQL::StaticValidation::MutationRootExistsError.new(
            'Schema is not configured for mutations',
            nodes: node
          ))
        else
          super
        end
      end
    end
  end
end
