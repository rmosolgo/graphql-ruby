# frozen_string_literal: true
# typed: true
module GraphQL
  module StaticValidation
    #--
    # @requires_ancestor: GraphQL::StaticValidation::BaseVisitor
    module MutationRootExists
      def on_operation_definition(node, _parent)
        if node.operation_type == 'mutation' && context.query.types.mutation_root.nil?
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
