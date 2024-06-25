# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module DirectivesAreDefined
      def initialize(*)
        super
      end

      def on_directive(node, parent)
        if !@types.directive_exists?(node.name)
          @directives_are_defined_errors_by_name ||= {}
          error = @directives_are_defined_errors_by_name[node.name] ||= begin
            err = GraphQL::StaticValidation::DirectivesAreDefinedError.new(
              "Directive @#{node.name} is not defined",
              nodes: [],
              directive: node.name
            )
            add_error(err)
            err
          end
          error.nodes << node
        else
          super
        end
      end
    end
  end
end
