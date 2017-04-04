# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class OperationNamesAreValid
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)
        op_names = Hash.new { |h, k| h[k] = [] }

        context.visitor[GraphQL::Language::Nodes::OperationDefinition].enter << ->(node, _parent) {
          op_names[node.name] << node
        }

        context.visitor[GraphQL::Language::Nodes::Document].leave << ->(node, _parent) {
          op_count = op_names.values.inject(0) { |m, v| m + v.size }

          op_names.each do |name, nodes|
            if name.nil? && op_count > 1
              context.errors << message(%|Operation name is required when multiple operations are present|, nodes, context: context)
            elsif nodes.length > 1
              context.errors << message(%|Operation name "#{name}" must be unique|, nodes, context: context)
            end
          end
        }
      end
    end
  end
end
