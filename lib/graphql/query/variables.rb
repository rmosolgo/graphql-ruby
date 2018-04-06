# frozen_string_literal: true
module GraphQL
  class Query
    # Read-only access to query variables, applying default values if needed.
    class Variables
      extend GraphQL::Delegate

      # @return [Array<GraphQL::Query::VariableValidationError>]  Any errors encountered when parsing the provided variables and literal values
      attr_reader :errors

      attr_reader :context

      def initialize(ctx, ast_variables, provided_variables)
        schema = ctx.schema
        @context = ctx
        @provided_variables = provided_variables
        normalized_provided_variables = if provided_variables.is_a?(Hash)
          provided_variables.reduce({}) do |h, (k, v)|
            normalized_k = GraphQL::Schema::Member::BuildType.camelize(k.to_s)
            h[normalized_k] = v
            h
          end
        else
          {}
        end
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
            if @provided_variables.key?(variable_name)
              provided_value = @provided_variables[variable_name]
              value_was_provided = true
            elsif normalized_provided_variables.key?(variable_name)
              provided_value = normalize_arguments(variable_type, normalized_provided_variables[variable_name])
              value_was_provided = true
            else
              provided_value = nil
              value_was_provided = false
            end

            validation_result = variable_type.validate_input(provided_value, ctx)
            if !validation_result.valid?
              # This finds variables that were required but not provided
              @errors << GraphQL::Query::VariableValidationError.new(ast_variable, variable_type, provided_value, validation_result)
            elsif value_was_provided
              # Add the variable if a value was provided
              memo[variable_name] = variable_type.coerce_input(provided_value, ctx)
            elsif default_value
              # Add the variable if it wasn't provided but it has a default value (including `null`)
              memo[variable_name] = GraphQL::Query::LiteralInput.coerce(variable_type, default_value, self)
            end
          end
        end
      end

      def_delegators :@storage, :length, :key?, :[], :fetch, :to_h

      private

      # TODO dedup with subscription
      #
      # Recursively normalize `args` as belonging to `arg_owner`:
      # - convert symbols to strings,
      # - if needed, camelize the string (using {#normalize_name})
      # @param arg_owner [GraphQL::Field, GraphQL::BaseType]
      # @param args [Hash, Array, Any] some GraphQL input value to coerce as `arg_owner`
      # @return [Any] normalized arguments value
      def normalize_arguments(arg_owner, args)
        case arg_owner
        when GraphQL::Field, GraphQL::InputObjectType
          normalized_args = {}
          args.each do |k, v|
            arg_name = k.to_s
            arg_defn = arg_owner.arguments[arg_name]
            if arg_defn
              normalized_arg_name = arg_name
            else
              normalized_arg_name = GraphQL::Schema::Member::BuildType.camelize(arg_name)
              arg_defn = arg_owner.arguments[normalized_arg_name]
            end

            if arg_defn
              normalized_args[normalized_arg_name] = normalize_arguments(arg_defn.type, v)
            end
          end

          normalized_args
        when GraphQL::ListType
          args.map { |a| normalize_arguments(arg_owner.of_type, a) }
        when GraphQL::NonNullType
          normalize_arguments(arg_owner.of_type, args)
        else
          args
        end
      end
    end
  end
end
