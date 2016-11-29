# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class DirectivesAreDefined
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)
        directive_names = context.schema.directives.keys
        context.visitor[GraphQL::Language::Nodes::Directive] << ->(node, parent) {
          validate_directive(node, directive_names, context)
        }
      end

      private

      def validate_directive(ast_directive, directive_names, context)
        if !directive_names.include?(ast_directive.name)
          context.errors << message("Directive @#{ast_directive.name} is not defined", ast_directive, context: context)
          GraphQL::Language::Visitor::SKIP
        else
          nil
        end
      end
    end
  end
end
