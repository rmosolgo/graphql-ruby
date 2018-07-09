# frozen_string_literal: true
module GraphQL
  class Query
    # Read-only access to query variables, applying default values if needed.
    class Variables
      extend Forwardable

      # @return [Array<GraphQL::Query::VariableValidationError>]  Any errors encountered when parsing the provided variables and literal values
      attr_reader :errors

      attr_reader :context

      def initialize(ctx, ast_variables, provided_variables)
        schema = ctx.schema
        @context = ctx

        @provided_variables = deep_stringify(provided_variables)
        @errors = []
        @storage = ast_variables.each_with_object({}) do |ast_variable, memo|
          # Find the right value for this variable:
          # - First, use the value provided at runtime
          # - Then, fall back to the default value from the query string
          # If it's still nil, raise an error if it's required.
          variable_type = schema.type_from_ast(ast_variable.type)
          if variable_type.nil?
            # Pass -- it will get handled by a validator
          else
            variable_name = ast_variable.name
            default_value = ast_variable.default_value
            provided_value = @provided_variables[variable_name]
            value_was_provided =  @provided_variables.key?(variable_name)

            begin
              validation_result = variable_type.validate_input(provided_value, ctx)
            rescue GraphQL::CoercionError => ex
              validation_result = GraphQL::Query::InputValidationResult.new
              validation_result.add_problem(ex.message)
            end

            if !validation_result.valid?
              # This finds variables that were required but not provided
              @errors << GraphQL::Query::VariableValidationError.new(ast_variable, variable_type, provided_value, validation_result)
            elsif value_was_provided
              # Add the variable if a value was provided
              memo[variable_name] = variable_type.coerce_input(provided_value, ctx)
            elsif default_value != nil
              # Add the variable if it wasn't provided but it has a default value (including `null`)
              memo[variable_name] = GraphQL::Query::LiteralInput.coerce(variable_type, default_value, self)
            end
          end
        end
      end

      def_delegators :@storage, :length, :key?, :[], :fetch, :to_h

      private

      def deep_stringify(val)
        case val
        when Array
          val.map { |v| deep_stringify(v) }
        when Hash
          new_val = {}
          val.each do |k, v|
            new_val[k.to_s] = deep_stringify(v)
          end
          new_val
        else
          val
        end
      end
    end
  end
end
