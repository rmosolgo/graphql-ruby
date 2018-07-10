# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module NoDefinitionsArePresent
      include GraphQL::StaticValidation::Message::MessageHelper

      def initialize(*)
        super
        @schema_definition_nodes = []
      end

      def on_invalid_node(node, parent)
        @schema_definition_nodes << node
      end

      # TODO Add extensions
      alias :on_directive_definition :on_invalid_node
      alias :on_schema_definition :on_invalid_node
      alias :on_scalar_type_definition :on_invalid_node
      alias :on_object_type_definition :on_invalid_node
      alias :on_input_object_type_definition :on_invalid_node
      alias :on_interface_type_definition :on_invalid_node
      alias :on_union_type_definition :on_invalid_node
      alias :on_enum_type_definition :on_invalid_node

      def on_document(node, parent)
        super
        if @schema_definition_nodes.any?
          add_error(%|Query cannot contain schema definitions|, @schema_definition_nodes)
        end
      end
    end
  end
end
