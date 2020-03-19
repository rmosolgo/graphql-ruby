# frozen_string_literal: true
module GraphQL
  class Schema
    class InputObject < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::AcceptsDefinition
      extend Forwardable
      extend GraphQL::Schema::Member::HasArguments
      extend GraphQL::Schema::Member::HasArguments::ArgumentObjectLoader
      extend GraphQL::Schema::Member::ValidatesInput

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
        maybe_lazies = []
        self.class.arguments.each do |name, arg_defn|
          @arguments_by_keyword[arg_defn.keyword] = arg_defn
          ruby_kwargs_key = arg_defn.keyword

          if @ruby_style_hash.key?(ruby_kwargs_key)
            loads = arg_defn.loads
            # Resolvers do this loading themselves;
            # With the interpreter, it's done during `coerce_arguments`
            if loads && !arg_defn.from_resolver? && !context.interpreter?
              value = @ruby_style_hash[ruby_kwargs_key]
              loaded_value = if arg_defn.type.list?
                value.map { |val| load_application_object(arg_defn, loads, val, context) }
              else
                load_application_object(arg_defn, loads, value, context)
              end
              maybe_lazies << context.schema.after_lazy(loaded_value) do |loaded_value|
                @ruby_style_hash[ruby_kwargs_key] = loaded_value
              end
            end

            # Weirdly, procs are applied during coercion, but not methods.
            # Probably because these methods require a `self`.
            if arg_defn.prepare.is_a?(Symbol) || context.nil? || !context.interpreter?
              @ruby_style_hash[ruby_kwargs_key] = arg_defn.prepare_value(self, @ruby_style_hash[ruby_kwargs_key])
            end
          end
        end

        @maybe_lazies = maybe_lazies
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
        if context
          context.schema.after_any_lazies(@maybe_lazies) do
            self
          end
        else
          self
        end
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
        @ruby_style_hash.key?(key) || (@arguments && @arguments.key?(key)) || false
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
          type_defn.ast_node = ast_node
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

        # @api private
        INVALID_OBJECT_MESSAGE = "Expected %{object} to be a key-value object responding to `to_h` or `to_unsafe_h`."


        def validate_non_null_input(input, ctx)
          result = GraphQL::Query::InputValidationResult.new

          warden = ctx.warden

          if input.is_a?(Array)
            result.add_problem(INVALID_OBJECT_MESSAGE % { object: JSON.generate(input, quirks_mode: true) })
            return result
          end

          # We're not actually _using_ the coerced result, we're just
          # using these methods to make sure that the object will
          # behave like a hash below, when we call `each` on it.
          begin
            input.to_h
          rescue
            begin
              # Handle ActionController::Parameters:
              input.to_unsafe_h
            rescue
              # We're not sure it'll act like a hash, so reject it:
              result.add_problem(INVALID_OBJECT_MESSAGE % { object: JSON.generate(input, quirks_mode: true) })
              return result
            end
          end

          visible_arguments_map = warden.arguments(self).reduce({}) { |m, f| m[f.name] = f; m}

          # Items in the input that are unexpected
          input.each do |name, value|
            if visible_arguments_map[name].nil?
              result.add_problem("Field is not defined on #{self.graphql_name}", [name])
            end
          end

          # Items in the input that are expected, but have invalid values
          visible_arguments_map.map do |name, argument|
            argument_result = argument.type.validate_input(input[name], ctx)
            if !argument_result.valid?
              result.merge_result!(name, argument_result)
            end
          end

          result
        end

        def coerce_input(value, ctx)
          if value.nil?
            return nil
          end

          input_values = coerce_arguments(nil, value, ctx)

          input_obj_instance = self.new(ruby_kwargs: input_values, context: ctx, defaults_used: nil)
          input_obj_instance.prepare
        end

        # It's funny to think of a _result_ of an input object.
        # This is used for rendering the default value in introspection responses.
        def coerce_result(value, ctx)
          # Allow the application to provide values as :symbols, and convert them to the strings
          value = value.reduce({}) { |memo, (k, v)| memo[k.to_s] = v; memo }

          result = {}

          arguments.each do |input_key, input_field_defn|
            input_value = value[input_key]
            if value.key?(input_key)
              result[input_key] = if input_value.nil?
                nil
              else
                input_field_defn.type.coerce_result(input_value, ctx)
              end
            end
          end

          result
        end
      end
    end
  end
end
