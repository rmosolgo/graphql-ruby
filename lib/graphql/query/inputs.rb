module GraphQL
  class Query
    # Hierarchical key-value sets where
    # children fall back to their parents
    # when they don't have values
    class Inputs
      def initialize(values, parent:)
        @values = values
        @parent = parent
      end

      def [](key)
        @values.fetch(key.to_s) { |missing_key| @parent[missing_key] }
      end

      def self.from_arguments(ast_arguments, argument_defns, variables)
        values_hash = {}
        ast_arguments.each do |arg|
          arg_defn = argument_defns[arg.name]
          value = reduce_value(arg.value, arg_defn.type, variables)
          values_hash[arg.name] = value
        end
        self.new(values_hash, parent: variables)
      end

      def self.from_variable_definitions(schema, ast_variables)
        values_hash = {}
        ast_variables.each do |ast_variable|
          if !ast_variable.default_value.nil?
            variable_type = schema.types[ast_variable.type.name]
            reduced_value = reduce_value(ast_variable.default_value, variable_type)
            values_hash[ast_variable.name] = reduced_value
          end
        end
        self.new(values_hash, parent: {})
      end

      private

      def self.reduce_value(value, type, variables = nil)
        if value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
          raw_value = variables[value.name]
          reduce_value(raw_value, type, variables)
        elsif value.is_a?(GraphQL::Language::Nodes::InputObject)
          wrapped_type = type.unwrap
          value = self.from_arguments(value.pairs, wrapped_type.input_fields, variables)
        elsif type.kind.list?
          value.map { |item| reduce_value(item, type.of_type, variables) }
        elsif type.kind.non_null?
          reduce_value(value, type.of_type, variables)
        elsif type.kind.scalar?
          type.coerce_input!(value)
        elsif type.kind.input_object? && value.is_a?(Hash)
          input_values = {}
          type.input_fields.each do |input_key, input_field_defn|
            raw_value = value.fetch(input_key, input_field_defn.default_value)
            reduced_value = reduce_value(raw_value, input_field_defn.type, variables)
            input_values[input_key] = reduced_value
          end
          self.new(input_values, parent: {})
        elsif type.kind.enum?
          value_name = if value.is_a?(String)
            value
          else
            value.name # it's a Nodes::Enum
          end
          type.coerce_input!(value_name)
        else
          raise "Unknown input #{value} of type #{type}"
        end
      end
    end
  end
end
