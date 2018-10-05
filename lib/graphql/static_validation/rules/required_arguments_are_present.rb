# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module RequiredArgumentsArePresent
      def on_field(node, _parent)
        assert_required_args(node, field_definition)
        super
      end

      def on_directive(node, _parent)
        directive_defn = context.schema.directives[node.name]
        assert_required_args(node, directive_defn)
        super
      end

      private

      def assert_required_args(ast_node, defn)
        present_argument_names = ast_node.arguments.map(&:name)
        required_argument_names = defn.arguments.values
          .select { |a| a.type.kind.non_null? }
          .map(&:name)

        missing_names = required_argument_names - present_argument_names
        if missing_names.any?
          add_error("#{ast_node.class.name.split("::").last} '#{ast_node.name}' is missing required arguments: #{missing_names.join(", ")}", ast_node)
        end
      end
    end
  end
end
