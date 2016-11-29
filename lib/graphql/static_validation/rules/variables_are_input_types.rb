# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class VariablesAreInputTypes
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)
        context.visitor[GraphQL::Language::Nodes::VariableDefinition] << ->(node, parent) {
          validate_is_input_type(node, context)
        }
      end

      private

      def validate_is_input_type(node, context)
        type_name = get_type_name(node.type)
        type = context.warden.get_type(type_name)

        if type.nil?
          context.errors << message("#{type_name} isn't a defined input type (on $#{node.name})", node, context: context)
        elsif !type.kind.input?
          context.errors << message("#{type.name} isn't a valid input type (on $#{node.name})", node, context: context)
        end
      end

      def get_type_name(ast_type)
        if ast_type.respond_to?(:of_type)
          get_type_name(ast_type.of_type)
        else
          ast_type.name
        end
      end
    end
  end
end
