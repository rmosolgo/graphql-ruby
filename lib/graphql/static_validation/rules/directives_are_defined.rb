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
          add_error("Directive @#{node.name} is not defined", node, extensions: {
            "rule": "StaticValidation::DirectivesAreDefined",
            "directive": node.name
          })
        else
          super
        end
      end
    end
  end
end
