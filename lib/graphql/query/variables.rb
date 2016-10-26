module GraphQL
  class Query
    # Read-only access to query variables, applying default values if needed.
    class Variables
      extend Forwardable

      # @return [Array<GraphQL::Query::VariableValidationError>]  Any errors encountered when parsing the provided variables and literal values
      attr_reader :errors

      def initialize(schema, warden, ast_variables, provided_variables)
        @schema = schema
        @warden = warden
        @provided_variables = provided_variables
        @errors = []
        @storage = ast_variables.each_with_object({}) do |ast_variable, memo|
          variable_name = ast_variable.name
          memo[variable_name] = get_graphql_value(ast_variable)
        end
      end

      def [](key)
        @storage.fetch(key)
      end

      def_delegators :@storage, :length

      private

      # Find the right value for this variable:
      # - First, use the value provided at runtime
      # - Then, fall back to the default value from the query string
      # If it's still nil, raise an error if it's required.
      def get_graphql_value(ast_variable)
        variable_type = @schema.type_from_ast(ast_variable.type)
        variable_name = ast_variable.name
        default_value = ast_variable.default_value
        provided_value = @provided_variables[variable_name]

        validation_result = variable_type.validate_input(provided_value, @warden)
        if !validation_result.valid?
          @errors << GraphQL::Query::VariableValidationError.new(ast_variable, variable_type, provided_value, validation_result)
        elsif provided_value.nil?
          GraphQL::Query::LiteralInput.coerce(variable_type, default_value, {})
        else
          variable_type.coerce_input(provided_value)
        end
      end
    end
  end
end
