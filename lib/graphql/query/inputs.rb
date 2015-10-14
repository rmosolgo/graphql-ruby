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
        key_s = key.to_s
        if @values.key?(key_s)
          @values[key_s]
        else
          @parent[key_s]
        end
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
            variable_type = schema.types[ast_variable.type]
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
        elsif value.is_a?(GraphQL::Language::Nodes::Enum)
          value = type.coerce_input!(value.name)
        elsif value.is_a?(GraphQL::Language::Nodes::InputObject)
          wrapped_type = type.unwrap
          value = self.from_arguments(value.pairs, wrapped_type.input_fields, variables)
        elsif type.kind.list?
          value.map { |item| reduce_value(item, type.of_type, variables) }
        elsif type.kind.non_null?
          reduce_value(value, type.of_type, variables)
        elsif type.kind.scalar?
          type.coerce_input!(value)
        else
          raise "Unknown input #{value} of type #{type}"
        end
      end
    end
  end
end
