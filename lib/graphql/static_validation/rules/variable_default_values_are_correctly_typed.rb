# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module VariableDefaultValuesAreCorrectlyTyped
      def on_variable_definition(node, parent)
        if !node.default_value.nil?
          value = node.default_value
          if node.type.is_a?(GraphQL::Language::Nodes::NonNullType)
            add_error("Non-null variable $#{node.name} can't have a default value", node)
          else
            type = context.schema.type_from_ast(node.type)
            if type.nil?
              # This is handled by another validator
            elsif !context.valid_literal?(value, type)
              add_error("Default value for $#{node.name} doesn't match type #{type}", node)
            end
          end
        end

        super
      end
    end
  end
end
