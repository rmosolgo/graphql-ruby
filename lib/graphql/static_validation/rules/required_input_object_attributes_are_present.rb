# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module RequiredInputObjectAttributesArePresent
      def on_input_object(node, parent)
        if parent.is_a? GraphQL::Language::Nodes::Argument
          validate_input_object(node, context, parent)
        end
        super
      end

      private

      def get_parent_type(context, parent)
        # If argument_definition is defined we're at nested object
        # and need to refer to the containing input object type rather
        # than the field_definition.
        # h/t @rmosolgo
        arg_defn = context.argument_definition

        # Double checking that arg_defn is an input object as nested
        # scalars, namely JSON, can make it to this branch
        defn = if arg_defn && arg_defn.type.unwrap.kind.input_object?
          arg_defn.type.unwrap
        else
          context.field_definition
        end

        parent_type = context.warden.arguments(defn)
          .find{|f| f.name == parent_name(parent, defn) }
        parent_type ? parent_type.type.unwrap : nil
      end

      def validate_input_object(ast_node, context, parent)
        parent_type = get_parent_type(context, parent)
        return unless parent_type && parent_type.kind.input_object?

        required_fields = parent_type.arguments
          .select{|k,v| v.type.kind.non_null?}
          .keys

        present_fields = ast_node.arguments.map(&:name)
        missing_fields = required_fields - present_fields

        missing_fields.each do |missing_field|
          path = [*context.path, missing_field]
          missing_field_type = parent_type.arguments[missing_field].type
          add_error(RequiredInputObjectAttributesArePresentError.new(
            "Argument '#{missing_field}' on InputObject '#{parent_type}' is required. Expected type #{missing_field_type}",
            argument_name: missing_field,
            argument_type: missing_field_type.to_s,
            input_object_type: parent_type.to_s,
            path: path,
            nodes: ast_node,
          ))
        end
      end
    end
  end
end
