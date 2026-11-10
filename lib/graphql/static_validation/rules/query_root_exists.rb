# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  module StaticValidation
    #--
    # @requires_ancestor: GraphQL::StaticValidation::BaseVisitor
    module QueryRootExists
      #: (GraphQL::Language::Nodes::OperationDefinition node, GraphQL::Language::Nodes::AbstractNode? _parent) -> void
      def on_operation_definition(node, _parent)
        if (node.operation_type == 'query' || node.operation_type.nil?) && context.types.query_root.nil?
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
