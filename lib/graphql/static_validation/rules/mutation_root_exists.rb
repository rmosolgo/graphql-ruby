# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module MutationRootExists
      def on_operation_definition(node, _parent)
        if node.operation_type == 'mutation' && context.warden.root_type_for_operation("mutation").nil?
          add_error('Schema is not configured for mutations', node, extensions: {
            "rule": "StaticValidation::MutationRootExists"
          })
        else
          super
        end
      end
    end
  end
end
