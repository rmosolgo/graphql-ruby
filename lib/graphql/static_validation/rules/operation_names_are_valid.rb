# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  module StaticValidation
    #--
    # @requires_ancestor: GraphQL::StaticValidation::BaseVisitor
    module OperationNamesAreValid
      #: (GraphQL::Language::Nodes::Document document, GraphQL::StaticValidation::ValidationContext context) -> void
      def initialize(document, context)
        super
        @operation_names = Hash.new { |h, k| h[k] = [] } #: Hash[String?, Array[GraphQL::Language::Nodes::OperationDefinition]]
      end

      #: (GraphQL::Language::Nodes::OperationDefinition node, GraphQL::Language::Nodes::AbstractNode? parent) -> void
      def on_operation_definition(node, parent)
        # The default proc creates the Array:
        operations = @operation_names[node.name] #: as !nil
        operations << node
        super
      end

      #: (GraphQL::Language::Nodes::Document node, GraphQL::Language::Nodes::AbstractNode? parent) -> void
      def on_document(node, parent)
        super
        op_count = @operation_names.values.inject(0) { |m, v| m + v.size }

        @operation_names.each do |name, nodes|
          if name.nil? && op_count > 1
            add_error(GraphQL::StaticValidation::OperationNamesAreValidError.new(
              %|Operation name is required when multiple operations are present|,
              nodes: nodes
            ))
          elsif nodes.length > 1
            add_error(GraphQL::StaticValidation::OperationNamesAreValidError.new(
              %|Operation name "#{name}" must be unique|,
              nodes: nodes,
              name: name
            ))
          end
        end
      end
    end
  end
end
