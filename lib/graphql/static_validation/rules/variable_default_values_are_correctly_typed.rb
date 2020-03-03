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
            type = context.schema.type_from_ast(node.type, context: context)
            if type.nil?
              # This is handled by another validator
            else
              begin
                valid = context.validate_literal(value, type)
                if valid.is_a?(GraphQL::Query::InputValidationResult)
                  validation_error = valid
                  valid = validation_error.valid?
                end
              rescue GraphQL::LiteralValidationError => validation_error
                # noop, we just want to stop any LiteralValidationError from propagating
              end

              if !valid
                if validation_error
                  problems = validation_error.problems
                  first_problem = problems && problems.first
                  if first_problem
                    error_message = first_problem["message"]
                  end
                end

                error_message ||= "Default value for $#{node.name} doesn't match type #{type.to_type_signature}"
                add_error(GraphQL::StaticValidation::VariableDefaultValuesAreCorrectlyTypedError.new(
                  error_message,
                  nodes: node,
                  name: node.name,
                  type: type.to_type_signature,
                  error_type: VariableDefaultValuesAreCorrectlyTypedError::VIOLATIONS[:INVALID_TYPE],
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
