# frozen_string_literal: true
module GraphQL
  class Query
    # Read-only access to values, normalizing all keys to strings
    #
    # {Arguments} recursively wraps the input in {Arguments} instances.
    class Arguments
      extend GraphQL::Delegate

      def initialize(values, argument_definitions:)
        @argument_values = values.inject({}) do |memo, (inner_key, inner_value)|
          arg_defn = argument_definitions[inner_key.to_s]

          arg_value = wrap_value(inner_value, arg_defn.type)
          string_key = arg_defn.expose_as
          memo[string_key] = ArgumentValue.new(string_key, arg_value, arg_defn)
          memo
        end
      end

      # @param key [String, Symbol] name or index of value to access
      # @return [Object] the argument at that key
      def [](key)
        key_s = key.is_a?(String) ? key : key.to_s
        @argument_values.fetch(key_s, NULL_ARGUMENT_VALUE).value
      end

      # @param key [String, Symbol] name of value to access
      # @return [Boolean] true if the argument was present in this field
      def key?(key)
        key_s = key.is_a?(String) ? key : key.to_s
        @argument_values.key?(key_s)
      end

      # Get the hash of all values, with stringified keys
      # @return [Hash] the stringified hash
      def to_h
        @to_h ||= begin
          h = {}
          each_value do |arg_value|
            arg_key = arg_value.definition.expose_as
            h[arg_key] = unwrap_value(arg_value.value)
          end
          h
        end
      end

      def_delegators :to_h, :keys, :values, :each

      # Access each key, value and type for the arguments in this set.
      # @yield [argument_value] The {ArgumentValue} for each argument
      # @yieldparam argument_value [ArgumentValue]
      def each_value
        @argument_values.each_value do |argument_value|
          yield(argument_value)
        end
      end

      NO_ARGS = self.new({}, argument_definitions: [])

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
        if value.nil?
          nil
        else
          case arg_defn_type
          when GraphQL::ListType
            value.map { |item| wrap_value(item, arg_defn_type.of_type) }
          when GraphQL::NonNullType
            wrap_value(value, arg_defn_type.of_type)
          when GraphQL::InputObjectType
            if value.is_a?(Hash)
              self.class.new(value, argument_definitions: arg_defn_type.arguments)
            else
              value
            end
          else
            value
          end
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
    end
  end
end
