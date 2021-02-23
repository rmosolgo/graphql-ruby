# frozen_string_literal: true
module GraphQL
  class Schema
    class InputObject < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::AcceptsDefinition
      extend Forwardable
      extend GraphQL::Schema::Member::HasArguments
      extend GraphQL::Schema::Member::HasArguments::ArgumentObjectLoader
      extend GraphQL::Schema::Member::ValidatesInput
      extend GraphQL::Schema::Member::HasValidators

      include GraphQL::Dig

      def initialize(arguments = nil, ruby_kwargs: nil, context:, defaults_used:)
        @context = context
        if ruby_kwargs
          @ruby_style_hash = ruby_kwargs
          @arguments = arguments
        else
          @arguments = self.class.arguments_class.new(arguments, context: context, defaults_used: defaults_used)
          # Symbolized, underscored hash:
          @ruby_style_hash = @arguments.to_kwargs
        end
        # Apply prepares, not great to have it duplicated here.
        maybe_lazies = []
        self.class.arguments.each_value do |arg_defn|
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
                overwrite_argument(ruby_kwargs_key, loaded_value)
              end
            end

            # Weirdly, procs are applied during coercion, but not methods.
            # Probably because these methods require a `self`.
            if arg_defn.prepare.is_a?(Symbol) || context.nil? || !context.interpreter?
              prepared_value = arg_defn.prepare_value(self, @ruby_style_hash[ruby_kwargs_key])
              overwrite_argument(ruby_kwargs_key, prepared_value)
            end
          end
        end

        @maybe_lazies = maybe_lazies
      end

      # @return [GraphQL::Query::Context] The context for this query
      attr_reader :context

      # @return [GraphQL::Query::Arguments, GraphQL::Execution::Interpereter::Arguments] The underlying arguments instance
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
            object = context[:current_object]
            # Pass this object's class with `as` so that messages are rendered correctly from inherited validators
            Schema::Validator.validate!(self.class.validators, object, context, @ruby_style_hash, as: self.class)
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
          class_eval <<-RUBY, __FILE__, __LINE__
            def #{method_name}
              self[#{method_name.inspect}]
            end
          RUBY
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

          if !(input.respond_to?(:to_h) || input.respond_to?(:to_unsafe_h))
            # We're not sure it'll act like a hash, so reject it:
            result.add_problem(INVALID_OBJECT_MESSAGE % { object: JSON.generate(input, quirks_mode: true) })
            return result
          end

          # Inject missing required arguments
          missing_required_inputs = self.arguments.reduce({}) do |m, (argument_name, argument)|
            if !input.key?(argument_name) && argument.type.non_null? && warden.get_argument(self, argument_name)
              m[argument_name] = nil
            end

            m
          end


          [input, missing_required_inputs].each do |args_to_validate|
            args_to_validate.each do |argument_name, value|
              argument = warden.get_argument(self, argument_name)
              # Items in the input that are unexpected
              unless argument
                result.add_problem("Field is not defined on #{self.graphql_name}", [argument_name])
                next
              end
              # Items in the input that are expected, but have invalid values
              argument_result = argument.type.validate_input(value, ctx)
              result.merge_result!(argument_name, argument_result) unless argument_result.valid?
            end
          end

          result
        end

        def coerce_input(value, ctx)
          if value.nil?
            return nil
          end

          arguments = coerce_arguments(nil, value, ctx)

          ctx.schema.after_lazy(arguments) do |resolved_arguments|
            if resolved_arguments.is_a?(GraphQL::Error)
              raise resolved_arguments
            else
              input_obj_instance = self.new(resolved_arguments, ruby_kwargs: resolved_arguments.keyword_arguments, context: ctx, defaults_used: nil)
              input_obj_instance.prepare
            end
          end
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

      private

      def overwrite_argument(key, value)
        # Argument keywords come in frozen from the interpreter, dup them before modifying them.
        if @ruby_style_hash.frozen?
          @ruby_style_hash = @ruby_style_hash.dup
        end
        @ruby_style_hash[key] = value
      end
    end
  end
end
