module GraphQL
  module Analysis
    class Analyzer
      def initialize(query)
        @query = query
      end

      def analyze?
        true
      end

      def result
        raise NotImplementedError
      end

      def on_enter_argument(node, parent, visitor)
      end

      def on_leave_argument(node, parent, visitor)
      end

      def on_enter_directive(node, parent, visitor)
      end

      def on_leave_directive(node, parent, visitor)
      end

      def on_enter_directive_definition(node, parent, visitor)
      end

      def on_leave_directive_definition(node, parent, visitor)
      end

      def on_enter_directive_location(node, parent, visitor)
      end

      def on_leave_directive_location(node, parent, visitor)
      end

      def on_enter_document(node, parent, visitor)
      end

      def on_leave_document(node, parent, visitor)
      end

      def on_enter_field(node, parent, visitor)
      end

      def on_leave_field(node, parent, visitor)
      end

      def on_enter_operation_definition(node, parent, visitor)
      end

      def on_leave_operation_definition(node, parent, visitor)
      end

      def on_enter_abstract_node(node, parent, visitor)
        # TODO: convert all aliases to proper methods
      end

      def on_leave_abstract_node(node, parent, visitor)
        # TODO: convert all aliases to proper methods
      end

      alias :on_document :on_enter_abstract_node
      alias :on_enum :on_enter_abstract_node
      alias :on_enum_type_definition :on_enter_abstract_node
      alias :on_enum_type_extension :on_enter_abstract_node
      alias :on_enum_value_definition :on_enter_abstract_node
      alias :on_fragment_definition :on_enter_abstract_node
      alias :on_fragment_spread :on_enter_abstract_node
      alias :on_inline_fragment :on_enter_abstract_node
      alias :on_input_object :on_enter_abstract_node
      alias :on_input_object_type_definition :on_enter_abstract_node
      alias :on_input_object_type_extension :on_enter_abstract_node
      alias :on_input_value_definition :on_enter_abstract_node
      alias :on_interface_type_definition :on_enter_abstract_node
      alias :on_interface_type_extension :on_enter_abstract_node
      alias :on_list_type :on_enter_abstract_node
      alias :on_non_null_type :on_enter_abstract_node
      alias :on_null_value :on_enter_abstract_node
      alias :on_object_type_definition :on_enter_abstract_node
      alias :on_object_type_extension :on_enter_abstract_node
      alias :on_scalar_type_definition :on_enter_abstract_node
      alias :on_scalar_type_extension :on_enter_abstract_node
      alias :on_schema_definition :on_enter_abstract_node
      alias :on_schema_extension :on_enter_abstract_node
      alias :on_type_name :on_enter_abstract_node
      alias :on_union_type_definition :on_enter_abstract_node
      alias :on_union_type_extension :on_enter_abstract_node
      alias :on_variable_definition :on_enter_abstract_node
      alias :on_variable_identifier :on_enter_abstract_node

      protected

      attr_reader :query, :visitor
    end
  end
end
