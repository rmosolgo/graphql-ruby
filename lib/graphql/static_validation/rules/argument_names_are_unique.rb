# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class ArgumentNamesAreUnique
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)
        context.visitor[GraphQL::Language::Nodes::Field] << ->(node, parent) {
          validate_arguments(node, context)
        }

        context.visitor[GraphQL::Language::Nodes::Directive] << ->(node, parent) {
          validate_arguments(node, context)
        }
      end

      def validate_arguments(node, context)
        argument_defns = node.arguments
        if argument_defns.any?
          args_by_name = Hash.new { |h, k| h[k] = [] }
          argument_defns.each { |a| args_by_name[a.name] << a }
          args_by_name.each do |name, defns|
            if defns.size > 1
              context.errors << message("There can be only one argument named \"#{name}\"", defns, context: context)
            end
          end
        end
      end
    end
  end
end
