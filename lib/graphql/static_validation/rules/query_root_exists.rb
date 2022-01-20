# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module QueryRootExists
      def on_operation_definition(node, _parent)
        if (node.operation_type == 'query' || node.operation_type.nil?) && context.warden.root_type_for_operation("query").nil?
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
