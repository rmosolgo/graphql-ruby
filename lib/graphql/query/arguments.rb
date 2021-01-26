# frozen_string_literal: true
module GraphQL
  class Query
    # Read-only access to values, normalizing all keys to strings
    #
    # {Arguments} recursively wraps the input in {Arguments} instances.
    class Arguments
      extend Forwardable
      include GraphQL::Dig

      def self.construct_arguments_class(argument_owner)
        argument_definitions = argument_owner.arguments
        argument_owner.arguments_class = Class.new(self) do
          self.argument_owner = argument_owner
          self.argument_definitions = argument_definitions

          argument_definitions.each do |_arg_name, arg_definition|
            if arg_definition.method_access?
              expose_as = arg_definition.expose_as.to_s.freeze
              expose_as_underscored = GraphQL::Schema::Member::BuildType.underscore(expose_as).freeze
              method_names = [expose_as, expose_as_underscored].uniq
              method_names.each do |method_name|
                # Don't define a helper method if it would override something.
                if method_defined?(method_name)
                  GraphQL::Deprecation.warn(
                    "Unable to define a helper for argument with name '#{method_name}' "\
                    "as this is a reserved name. Add `method_access: false` to stop this warning."
                  )
                else
                  define_method(method_name) do
                    # Always use `expose_as` here, since #[] doesn't accept underscored names
                    self[expose_as]
                  end
                end
              end
            end
          end
        end
      end

      attr_reader :argument_values

      def initialize(values, context:, defaults_used:)
        @argument_values = values.inject({}) do |memo, (inner_key, inner_value)|
          arg_name = inner_key.to_s
          arg_defn = self.class.argument_definitions[arg_name] || raise("Not found #{arg_name} among #{self.class.argument_definitions.keys}")
          arg_default_used = defaults_used.include?(arg_name)
          arg_value = wrap_value(inner_value, arg_defn.type, context)
          string_key = arg_defn.expose_as
          memo[string_key] = ArgumentValue.new(string_key, arg_value, arg_defn, arg_default_used)
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

      # @param key [String, Symbol] name of value to access
      # @return [Boolean] true if the argument default was passed as the argument value to the resolver
      def default_used?(key)
        key_s = key.is_a?(String) ? key : key.to_s
        @argument_values.fetch(key_s, NULL_ARGUMENT_VALUE).default_used?
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
      def_delegators :@argument_values, :any?

      def prepare
        self
      end

      # Access each key, value and type for the arguments in this set.
      # @yield [argument_value] The {ArgumentValue} for each argument
      # @yieldparam argument_value [ArgumentValue]
      def each_value
        @argument_values.each_value do |argument_value|
          yield(argument_value)
        end
      end

      class << self
        attr_accessor :argument_definitions, :argument_owner
      end

      NoArguments = Class.new(self) do
        self.argument_definitions = []
      end

      NO_ARGS = NoArguments.new({}, context: nil, defaults_used: Set.new)

      # Convert this instance into valid Ruby keyword arguments
      # @return [{Symbol=>Object}]
      def to_kwargs
        ruby_kwargs = {}

        keys.each do |key|
          ruby_kwargs[Schema::Member::BuildType.underscore(key).to_sym] = self[key]
        end

        ruby_kwargs
      end

      alias :to_hash :to_kwargs

      private

      class ArgumentValue
        attr_reader :key, :value, :definition
        attr_writer :default_used

        def initialize(key, value, definition, default_used)
          @key = key
          @value = value
          @definition = definition
          @default_used = default_used
        end

        # @return [Boolean] true if the argument default was passed as the argument value to the resolver
        def default_used?
          @default_used
        end
      end

      NULL_ARGUMENT_VALUE = ArgumentValue.new(nil, nil, nil, nil)

      def wrap_value(value, arg_defn_type, context)
        if value.nil?
          nil
        else
          case arg_defn_type
          when GraphQL::ListType
            value.map { |item| wrap_value(item, arg_defn_type.of_type, context) }
          when GraphQL::NonNullType
            wrap_value(value, arg_defn_type.of_type, context)
          when GraphQL::InputObjectType
            if value.is_a?(Hash)
              result = arg_defn_type.arguments_class.new(value, context: context, defaults_used: Set.new)
              result.prepare
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
        when GraphQL::Query::Arguments, GraphQL::Schema::InputObject
          value.to_h
        else
          value
        end
      end
    end
  end
end
