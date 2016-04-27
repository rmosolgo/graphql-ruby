module GraphQL
  module StaticValidation
    class DirectivesAreDefined
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)
        directive_names = context.schema.directives.keys
        context.visitor[GraphQL::Language::Nodes::Directive] << -> (node, parent) {
          validate_directive(node, directive_names, context.errors)
        }
      end

      private

      def validate_directive(ast_directive, directive_names, errors)
        if !directive_names.include?(ast_directive.name)
          errors << message("Directive @#{ast_directive.name} is not defined", ast_directive)
        end
      end
    end
  end
end
