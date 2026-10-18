# frozen_string_literal: true
# typed: true
module GraphQL
  module StaticValidation
    #--
    # @requires_ancestor: GraphQL::StaticValidation::BaseVisitor
    module QueryRootExists
      def on_operation_definition(node, _parent)
        if (node.operation_type == 'query' || node.operation_type.nil?) && context.query.types.query_root.nil?
          add_error(GraphQL::StaticValidation::QueryRootExistsError.new(
            'Schema is not configured for queries',
            nodes: node
          ))
        else
          super
        end
      end
    end
  end
end
