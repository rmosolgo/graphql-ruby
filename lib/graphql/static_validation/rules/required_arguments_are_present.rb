# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class RequiredArgumentsArePresent
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)
        v = context.visitor
        v[GraphQL::Language::Nodes::Field] << ->(node, parent) { validate_field(node, context) }
        v[GraphQL::Language::Nodes::Directive] << ->(node, parent) { validate_directive(node, context) }
      end

      private

      def validate_directive(ast_directive, context)
        directive_defn = context.schema.directives[ast_directive.name]
        assert_required_args(ast_directive, directive_defn, context)
      end

      def validate_field(ast_field, context)
        defn = context.field_definition
        assert_required_args(ast_field, defn, context)
      end

      def assert_required_args(ast_node, defn, context)
        present_argument_names = ast_node.arguments.map(&:name)
        required_argument_names = defn.arguments.values
          .select { |a| a.type.kind.non_null? }
          .map(&:name)

        missing_names = required_argument_names - present_argument_names
        if missing_names.any?
          context.errors << message("#{ast_node.class.name.split("::").last} '#{ast_node.name}' is missing required arguments: #{missing_names.join(", ")}", ast_node, context: context)
        end
      end
    end
  end
end
