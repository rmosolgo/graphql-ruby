# frozen_string_literal: true
module GraphQL
  module StaticValidation
    # Optional validation not included in default validator.
    #
    # @example Initialize validator with optional rules
    #   validator = GraphQL::StaticValidation::Validator.new(schema: MySchema, rules: GraphQL::StaticValidation::OPTIONAL_RULES)
    #
    class NoDeprecatedFields
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)
        v = context.visitor
        v[GraphQL::Language::Nodes::Field] << ->(node, parent) { validate_field(node, context) }
        v[GraphQL::Language::Nodes::Directive] << ->(node, parent) { validate_directive(node, context) }
      end

      private

      def validate_directive(ast_directive, context)
        directive_defn = context.schema.directives[ast_directive.name]
        assert_deprecated_field(ast_directive, directive_defn, context)
      end

      def validate_field(ast_field, context)
        defn = context.field_definition
        assert_deprecated_field(ast_field, defn, context)
      end

      def assert_deprecated_field(ast_node, defn, context)
        deprecation_reason = defn.deprecation_reason
        if deprecation_reason
          context.errors << message("#{ast_node.class.name.split("::").last} '#{ast_node.name}' is deprecated: '#{deprecation_reason}'", ast_node, context: context)
        end
      end
    end
  end
end
