module GraphQL
  class Query
    # Turn query string values into something useful for query execution
    class LiteralInput
      attr_reader :variables, :value, :type
      def initialize(type, incoming_value, variables)
        @type = type
        @value = incoming_value
        @variables = variables
      end

      def graphql_value
        if value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
          variables[value.name] # Already cleaned up with RubyInput
        elsif type.kind.input_object?
          input_values = {}
          inner_type = type.unwrap
          inner_type.input_fields.each do |arg_name, arg_defn|
            ast_arg = value.pairs.find { |ast_arg| ast_arg.name == arg_name }
            raw_value = resolve_argument_value(ast_arg, arg_defn, variables)
            reduced_value = coerce(arg_defn.type, raw_value, variables)
            input_values[arg_name] = reduced_value
          end
          input_values
        elsif type.kind.list?
          inner_type = type.of_type
          value.map { |item| coerce(inner_type, item, variables) }
        elsif type.kind.non_null?
          inner_type = type.of_type
          coerce(inner_type, value, variables)
        elsif type.kind.scalar?
          type.coerce_input!(value)
        elsif type.kind.enum?
          value_name = value.name # it's a Nodes::Enum
          type.coerce_input!(value_name)
        else
          raise "Unknown input #{value} of type #{type}"
        end
      end

      def self.coerce(type, value, variables)
        input = self.new(type, value, variables)
        input.graphql_value
      end

      def self.from_arguments(ast_arguments, argument_defns, variables)
        values_hash = {}
        argument_defns.each do |arg_name, arg_defn|
          ast_arg = ast_arguments.find { |ast_arg| ast_arg.name == arg_name }
          arg_value = nil
          if ast_arg
            arg_value = coerce(arg_defn.type, ast_arg.value, variables)
          end
          if arg_value.nil?
            arg_value = arg_defn.default_value
          end
          values_hash[arg_name] = arg_value
        end
        GraphQL::Query::Arguments.new(values_hash)
      end

      private

      def coerce(*args)
        self.class.coerce(*args)
      end

      def resolve_argument_value(*args)
        self.class.resolve_argument_value(*args)
      end

      # Prefer values in this order:
      # - Literal value from the query string
      # - Variable value from query varibles
      # - Default value from Argument definition
      def self.resolve_argument_value(ast_arg, arg_defn, variables)
        if !ast_arg.nil?
          raw_value = ast_arg.value
        end

        if raw_value.nil?
          raw_value = arg_defn.default_value
        end

        raw_value
      end
    end
  end
end
