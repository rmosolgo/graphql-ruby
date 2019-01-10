# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module DirectivesAreDefined
      def initialize(*)
        super
        @directive_names = context.schema.directives.keys
      end

      def on_directive(node, parent)
        if !@directive_names.include?(node.name)
          add_error(GraphQL::StaticValidation::DirectivesAreDefinedError.new(
            "Directive @#{node.name} is not defined",
            nodes: node,
            directive: node.name
          ))
        else
          super
        end
      end
    end
  end
end
