# frozen_string_literal: true
module GraphQL
  class Schema
    class InputObject < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::AcceptsDefinition
      extend Forwardable
      extend GraphQL::Schema::Member::HasArguments
      include GraphQL::Dig

      def initialize(values = nil, ruby_kwargs: nil, context:, defaults_used:)
        @context = context
        if ruby_kwargs
          @ruby_style_hash = ruby_kwargs
        else
          @arguments = self.class.arguments_class.new(values, context: context, defaults_used: defaults_used)
          # Symbolized, underscored hash:
          @ruby_style_hash = @arguments.to_kwargs
        end
        # Apply prepares, not great to have it duplicated here.
        @arguments_by_keyword = {}
        self.class.arguments.each do |name, arg_defn|
          @arguments_by_keyword[arg_defn.keyword] = arg_defn
          ruby_kwargs_key = arg_defn.keyword
          loads = arg_defn.loads

          if @ruby_style_hash.key?(ruby_kwargs_key) && loads && !arg_defn.from_resolver?
            value = @ruby_style_hash[ruby_kwargs_key]
            @ruby_style_hash[ruby_kwargs_key] = if arg_defn.type.list?
              GraphQL::Execution::Lazy.all(value.map { |val| load_application_object(arg_defn, loads, val) })
            else
              load_application_object(arg_defn, loads, value)
            end
          end

          if @ruby_style_hash.key?(ruby_kwargs_key) && arg_defn.prepare
            @ruby_style_hash[ruby_kwargs_key] = arg_defn.prepare_value(self, @ruby_style_hash[ruby_kwargs_key])
          end
        end
      end

      # @return [GraphQL::Query::Context] The context for this query
      attr_reader :context

      # @return [GraphQL::Query::Arguments] The underlying arguments instance
      attr_reader :arguments

      # Ruby-like hash behaviors, read-only
      def_delegators :@ruby_style_hash, :keys, :values, :each, :map, :any?, :empty?

      def to_h
        @ruby_style_hash.inject({}) do |h, (key, value)|
          h.merge(key => unwrap_value(value))
        end
      end

      def to_hash
        to_h
      end

      def prepare
        self
      end

      def unwrap_value(value)
        case value
        when Array
          value.map { |item| unwrap_value(item) }
        when Hash
          value.inject({}) do |h, (key, value)|
            h.merge(key => unwrap_value(value))
          end
        when InputObject
          value.to_h
        else
          value
        end
      end

      # Lookup a key on this object, it accepts new-style underscored symbols
      # Or old-style camelized identifiers.
      # @param key [Symbol, String]
      def [](key)
        if @ruby_style_hash.key?(key)
          @ruby_style_hash[key]
        elsif @arguments
          @arguments[key]
        else
          nil
        end
      end

      def key?(key)
        @ruby_style_hash.key?(key) || (@arguments && @arguments.key?(key))
      end

      # A copy of the Ruby-style hash
      def to_kwargs
        @ruby_style_hash.dup
      end

      class << self
        # @return [Class<GraphQL::Arguments>]
        attr_accessor :arguments_class

        def argument(*args, **kwargs, &block)
          argument_defn = super(*args, **kwargs, &block)
          # Add a method access
          method_name = argument_defn.keyword
          define_method(method_name) do
            self[method_name]
          end
        end

        def to_graphql
          type_defn = GraphQL::InputObjectType.new
          type_defn.name = graphql_name
          type_defn.description = description
          type_defn.metadata[:type_class] = self
          type_defn.mutation = mutation
          arguments.each do |name, arg|
            type_defn.arguments[arg.graphql_definition.name] = arg.graphql_definition
          end
          # Make a reference to a classic-style Arguments class
          self.arguments_class = GraphQL::Query::Arguments.construct_arguments_class(type_defn)
          # But use this InputObject class at runtime
          type_defn.arguments_class = self
          type_defn
        end

        def kind
          GraphQL::TypeKinds::INPUT_OBJECT
        end
      end
    end
  end
end
