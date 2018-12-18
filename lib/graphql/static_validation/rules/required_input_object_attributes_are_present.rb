# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class RequiredInputObjectAttributesArePresent
      include GraphQL::StaticValidation::Message::MessageHelper
      include GraphQL::StaticValidation::ArgumentsValidator::ArgumentsValidatorHelpers

      def validate(context)
        visitor = context.visitor
        visitor[GraphQL::Language::Nodes::InputObject] << ->(node, parent) {
          next unless parent.is_a? GraphQL::Language::Nodes::Argument
          validate_input_object(node, context, parent)
        }
      end

      private

      def get_parent_type(context, parent)
        defn = context.field_definition
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
          path = [ *context.path, missing_field]
          missing_field_type = parent_type.arguments[missing_field].type
          context.errors << message("Argument '#{missing_field}' on InputObject '#{parent_type}' is required. Expected type #{missing_field_type}", ast_node, path: path, context: context)
        end
      end
    end
  end
end
