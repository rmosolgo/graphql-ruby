module GraphQL
  class Query
    # Read-only access to values, normalizing all keys to strings
    #
    # {Arguments} recursively wraps the input in {Arguments} instances.
    class Arguments
      extend Forwardable

      ### Ruby 1.9.3 unofficial support
      # def initialize(values, argument_definitions:)
      def initialize(values, options = {})
        argument_definitions = options[:argument_definitions]

        @original_values = values
        @argument_values = values.inject({}) do |memo, (inner_key, inner_value)|
          string_key = inner_key.to_s
          arg_defn = argument_definitions[string_key]
          arg_value = wrap_value(inner_value, arg_defn.type)
          memo[string_key] = ArgumentValue.new(string_key, arg_value, arg_defn)
          memo
        end
      end

      # @param key [String, Symbol] name or index of value to access
      # @return [Object] the argument at that key
      def [](key)
        @argument_values.fetch(key.to_s, NULL_ARGUMENT_VALUE).value
      end

      # @param key [String, Symbol] name of value to access
      # @return [Boolean] true if the argument was present in this field
      def key?(key)
        @argument_values.key?(key.to_s)
      end

      # Get the original Ruby hash
      # @return [Hash] the original values hash
      def to_h
        @unwrapped_values ||= unwrap_value(@original_values)
      end

      def_delegators :string_key_values, :keys, :values, :each

      # Access each key, value and type for the arguments in this set.
      # @yield [argument_value] The {ArgumentValue} for each argument
      # @yieldparam argument_value [ArgumentValue]
      def each_value
        @argument_values.each_value do |argument_value|
          yield(argument_value)
        end
      end

      private

      class ArgumentValue
        attr_reader :key, :value, :definition
        def initialize(key, value, definition)
          @key = key
          @value = value
          @definition = definition
        end
      end

      NULL_ARGUMENT_VALUE = ArgumentValue.new(nil, nil, nil)

      def wrap_value(value, arg_defn_type)
        case value
        when Array
          value.map { |item| wrap_value(item, arg_defn_type.of_type) }
        when Hash
          if arg_defn_type.unwrap.kind.input_object?
            self.class.new(value, argument_definitions: arg_defn_type.arguments)
          else
            # It may be a custom scalar that coerces to a Hash
            value
          end
        else
          value
        end
      end

      def unwrap_value(value)
        case value
        when Array
          value.map { |item| unwrap_value(item) }
        when Hash
          value.inject({}) do |memo, (key, value)|
            memo[key] = unwrap_value(value)
            memo
          end
        when GraphQL::Query::Arguments
          value.to_h
        else
          value
        end
      end

      def string_key_values
        @string_key_values ||= stringify_keys(to_h)
      end

      def stringify_keys(value)
        case value
        when Hash
          value.inject({}) { |memo, (k, v)| memo[k.to_s] = stringify_keys(v); memo }
        when Array
          value.map { |v| stringify_keys(v) }
        else
          value
        end
      end
    end
  end
end
