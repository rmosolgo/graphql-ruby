# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module RequiredArgumentsArePresent
      def on_field(node, _parent)
        assert_required_args(node, field_definition)
        super
      end

      def on_directive(node, _parent)
        directive_defn = context.schema_directives[node.name]
        assert_required_args(node, directive_defn)
        super
      end

      private

      def assert_required_args(ast_node, defn)
        args = @context.query.types.arguments(defn)
        return if args.empty?
        # Fast path: if no arguments are required, skip all the work
        required_argument_names = nil
        args.each do |a|
          if a.type.kind.non_null? && !a.default_value? && @types.argument(defn, a.name)
            (required_argument_names ||= []) << a.graphql_name
          end
        end
        return if required_argument_names.nil?

        present_argument_names = ast_node.arguments.map(&:name)
        missing_names = required_argument_names - present_argument_names
        if !missing_names.empty?
          add_error(GraphQL::StaticValidation::RequiredArgumentsArePresentError.new(
            "#{ast_node.class.name.split("::").last} '#{ast_node.name}' is missing required arguments: #{missing_names.join(", ")}",
            nodes: ast_node,
            class_name: ast_node.class.name.split("::").last,
            name: ast_node.name,
            arguments: "#{missing_names.join(", ")}"
          ))
        end
      end
    end
  end
end
