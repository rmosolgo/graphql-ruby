# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module VariableDefaultValuesAreCorrectlyTyped
      def on_variable_definition(node, parent)
        if !node.default_value.nil?
          value = node.default_value
          if node.type.is_a?(GraphQL::Language::Nodes::NonNullType)
            add_error(GraphQL::StaticValidation::VariableDefaultValuesAreCorrectlyTypedError.new(
              "Non-null variable $#{node.name} can't have a default value",
              nodes: node,
              name: node.name,
              error_type: VariableDefaultValuesAreCorrectlyTypedError::VIOLATIONS[:INVALID_ON_NON_NULL]
            ))
          else
            type = context.schema.type_from_ast(node.type)
            if type.nil?
              # This is handled by another validator
            else
              begin
                valid = context.valid_literal?(value, type)
              rescue GraphQL::CoercionError => err
                error_message = err.message
              rescue GraphQL::LiteralValidationError
                # noop, we just want to stop any LiteralValidationError from propagating
              end

              if !valid
                error_message ||= "Default value for $#{node.name} doesn't match type #{type}"
                VariableDefaultValuesAreCorrectlyTypedError
                add_error(GraphQL::StaticValidation::VariableDefaultValuesAreCorrectlyTypedError.new(
                  error_message,
                  nodes: node,
                  name: node.name,
                  type: type.to_s,
                  error_type: VariableDefaultValuesAreCorrectlyTypedError::VIOLATIONS[:INVALID_TYPE]
                ))
              end
            end
          end
        end

        super
      end
    end
  end
end
