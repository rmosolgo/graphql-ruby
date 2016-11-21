module GraphQL
  module StaticValidation
    class UniqueDirectivesPerLocation
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)
        nodes_with_directives = GraphQL::Language::Nodes.constants
          .map{|c| GraphQL::Language::Nodes.const_get(c)}
          .select{|c| c.is_a?(Class) && c.instance_methods.include?(:directives)}

        nodes_with_directives.each do |node_class|
          context.visitor[node_class] << ->(node, _) {
            validate_directives(node, context) unless node.directives.empty?
          }
        end
      end

      private

      def validate_directives(node, context)
        used_directives = {}

        node.directives.each do |ast_directive|
          directive_name = ast_directive.name
          if used_directives[directive_name]
            context.errors << message(
              "The directive \"#{directive_name}\" can only be used once at this location.",
              [used_directives[directive_name], ast_directive],
              context: context
            )
          else
            used_directives[directive_name] = ast_directive
          end
        end
      end
    end
  end
end
