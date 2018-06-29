# frozen_string_literal: true

module GraphQL
  class Schema
    # A class-based container for field configuration and resolution logic. It supports:
    #
    # - Arguments, via `.argument(...)` helper, which will be applied to the field.
    # - Return type, via `.type(..., null: ...)`, which will be applied to the field.
    # - Description, via `.description(...)`, which will be applied to the field
    # - Resolution, via `#resolve(**args)` method, which will be called to resolve the field.
    # - `#object` and `#context` accessors for use during `#resolve`.
    #
    # Resolvers can be attached with the `resolver:` option in a `field(...)` call.
    #
    # A resolver's configuration may be overridden with other keywords in the `field(...)` call.
    #
    # See the {.field_options} to see how a Resolver becomes a set of field configuration options.
    #
    # @see {GraphQL::Schema::Mutation} for a concrete subclass of `Resolver`.
    # @see {GraphQL::Function} `Resolver` is a replacement for `GraphQL::Function`
    class Resolver
      include Schema::Member::GraphQLTypeNames
      # Really we only need description from here, but:
      extend Schema::Member::BaseDSLMethods
      extend GraphQL::Schema::Member::HasArguments

      # @param object [Object] the initialize object, pass to {Query.initialize} as `root_value`
      # @param context [GraphQL::Query::Context]
      def initialize(object:, context:)
        @object = object
        @context = context
        # Since this hash is constantly rebuilt, cache it for this call
        @arguments_by_keyword = {}
        self.class.arguments.each do |name, arg|
          @arguments_by_keyword[arg.keyword] = arg
        end
        @arguments_loads_as_type = self.class.arguments_loads_as_type
      end

      # @return [Object] The application object this field is being resolved on
      attr_reader :object

      # @return [GraphQL::Query::Context]
      attr_reader :context

      # This method is _actually_ called by the runtime,
      # it does some preparation and then eventually calls
      # the user-defined `#resolve` method.
      # @api private
      def resolve_with_support(**args)
        # First call the before_prepare hook which may raise
        before_prepare_val = if args.any?
          before_prepare(**args)
        else
          before_prepare
        end
        context.schema.after_lazy(before_prepare_val) do
          # Then call each prepare hook, which may return a different value
          # for that argument, or may return a lazy object
          load_arguments_val = load_arguments(args)
          context.schema.after_lazy(load_arguments_val) do |loaded_args|
            # Then validate each argument, which may raise or may return a lazy object
            validate_arguments_val = validate_arguments(loaded_args)
            context.schema.after_lazy(validate_arguments_val) do |validated_args|
              # Finally, all the hooks have passed, so resolve it
              if validated_args.any?
                public_send(self.class.resolve_method, **validated_args)
              else
                public_send(self.class.resolve_method)
              end
            end
          end
        end
      end

      # Do the work. Everything happens here.
      # @return [Object] An object corresponding to the return type
      def resolve(**args)
        raise NotImplementedError, "#{self.class.name}#resolve should execute the field's logic"
      end

      # Called before arguments are prepared.
      # Implement this hook to make checks before doing any work.
      #
      # If it returns a lazy object (like a promise), it will be synced by GraphQL
      # (but the resulting value won't be used).
      #
      # @param args [Hash] The input arguments, if there are any
      # @raise [GraphQL::ExecutionError] To add an error to the response
      # @raise [GraphQL::UnauthorizedError] To signal an authorization failure
      def before_prepare(**args)
      end

      private

      def load_arguments(args)
        prepared_args = {}
        prepare_lazies = []

        args.each do |key, value|
          arg_defn = @arguments_by_keyword[key]
          if arg_defn
            prepped_value = prepared_args[key] = load_argument(key, value)
            if context.schema.lazy?(prepped_value)
              prepare_lazies << context.schema.after_lazy(prepped_value) do |finished_prepped_value|
                prepared_args[key] = finished_prepped_value
              end
            end
          else
            # These are `extras: [...]`
            prepared_args[key] = value
          end
        end

        # Avoid returning a lazy if none are needed
        if prepare_lazies.any?
          GraphQL::Execution::Lazy.all(prepare_lazies).then { prepared_args }
        else
          prepared_args
        end
      end

      def load_argument(name, value)
        public_send("load_#{name}", value)
      end

      # TODO dedup with load_arguments
      def validate_arguments(args)
        validate_lazies = []
        args.each do |key, value|
          arg_defn = @arguments_by_keyword[key]
          if arg_defn
            validate_return = validate_argument(key, value)
            if context.schema.lazy?(validate_return)
              validate_lazies << context.schema.after_lazy(validate_return).then { "no-op" }
            end
          end
        end

        # Avoid returning a lazy if none are needed
        if validate_lazies.any?
          GraphQL::Execution::Lazy.all(validate_lazies).then { args }
        else
          args
        end
      end

      def validate_argument(name, value)
        public_send("validate_#{name}", value)
      end

      class LoadApplicationObjectFailedError < GraphQL::ExecutionError
        # @return [GraphQL::Schema::Argument] the argument definition for the argument that was looked up
        attr_reader :argument
        # @return [String] The ID provided by the client
        attr_reader :id
        # @return [Object] The value found with this ID
        attr_reader :object
        def initialize(argument:, id:, object:)
          @id = id
          @argument = argument
          @object = object
          super("No object found for `#{argument.graphql_name}: #{id.inspect}`")
        end
      end

      def load_application_object(arg_kwarg, id)
        argument = @arguments_by_keyword[arg_kwarg]
        # See if any object can be found for this ID
        application_object = context.schema.object_from_id(id, context)
        if application_object.nil?
          raise LoadApplicationObjectFailedError.new(argument: argument, id: id, object: application_object)
        end
        # Double-check that the located object is actually of this type
        # (Don't want to allow arbitrary access to objects this way)
        lookup_as_type = @arguments_loads_as_type[arg_kwarg]
        application_object_type = context.schema.resolve_type(lookup_as_type, application_object, context)
        possible_object_types = context.schema.possible_types(lookup_as_type)
        if !possible_object_types.include?(application_object_type)
          raise LoadApplicationObjectFailedError.new(argument: argument, id: id, object: application_object)
        else
          # This object was loaded successfully
          # and resolved to the right type,
          # now apply the `.authorized?` class method if there is one
          if (class_based_type = application_object_type.metadata[:type_class])
            context.schema.after_lazy(class_based_type.authorized?(application_object, context)) do |authed|
              if authed
                application_object
              else
                raise GraphQL::UnauthorizedError.new(
                  object: application_object,
                  type: class_based_type,
                  context: context,
                )
              end
            end
          else
            application_object
          end
        end
      rescue LoadApplicationObjectFailedError => err
        # pass it to a handler
        load_application_object_failed(err)
      end

      def load_application_object_failed(err)
        raise err
      end

      class << self
        # Default `:resolve` set below.
        # @return [Symbol] The method to call on instances of this object to resolve the field
        def resolve_method(new_method = nil)
          if new_method
            @resolve_method = new_method
          end
          @resolve_method || (superclass.respond_to?(:resolve_method) ? superclass.resolve_method : :resolve)
        end

        # Additional info injected into {#resolve}
        # @see {GraphQL::Schema::Field#extras}
        def extras(new_extras = nil)
          if new_extras
            @own_extras = new_extras
          end
          own_extras = @own_extras || []
          own_extras + (superclass.respond_to?(:extras) ? superclass.extras : [])
        end

        # Specifies whether or not the field is nullable. Defaults to `true`
        # TODO unify with {#type}
        # @param allow_null [Boolean] Whether or not the response can be null
        def null(allow_null = nil)
          if !allow_null.nil?
            @null = allow_null
          end

          @null.nil? ? (superclass.respond_to?(:null) ? superclass.null : true) : @null
        end

        # Call this method to get the return type of the field,
        # or use it as a configuration method to assign a return type
        # instead of generating one.
        # TODO unify with {#null}
        # @param new_type [Class, nil] If a type definition class is provided, it will be used as the return type of the field
        # @param null [true, false] Whether or not the field may return `nil`
        # @return [Class] The type which this field returns.
        def type(new_type = nil, null: nil)
          if new_type
            if null.nil?
              raise ArgumentError, "required argument `null:` is missing"
            end
            @type_expr = new_type
            @null = null
          else
            if @type_expr
              GraphQL::Schema::Member::BuildType.parse_type(@type_expr, null: @null)
            elsif superclass.respond_to?(:type)
              superclass.type
            else
              nil
            end
          end
        end

        # Specifies the complexity of the field. Defaults to `1`
        # @return [Integer, Proc]
        def complexity(new_complexity = nil)
          if new_complexity
            @complexity = new_complexity
          end
          @complexity || (superclass.respond_to?(:complexity) ? superclass.complexity : 1)
        end

        def field_options
          {
            type: type_expr,
            description: description,
            extras: extras,
            method: :resolve_with_support,
            resolver_class: self,
            arguments: arguments,
            null: null,
            complexity: complexity,
          }
        end

        # A non-normalized type configuration, without `null` applied
        def type_expr
          @type_expr || (superclass.respond_to?(:type_expr) ? superclass.type_expr : nil)
        end

        # Add an argument to this field's signature, but
        # also add some preparation hook methods which will be used for this argument
        # @see {GraphQL::Schema::Argument#initialize} for the signature
        def argument(name, type, *rest, loads: nil, **kwargs, &block)
          if loads
            arg_keyword = name.to_s.sub(/_id$/, "").to_sym
            kwargs[:as] = arg_keyword
            own_arguments_loads_as_type[arg_keyword] = loads
          end
          arg_defn = super(name, type, *rest, **kwargs, &block)

          if loads
            class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def load_#{arg_defn.keyword}(value)
              load_application_object(:#{arg_defn.keyword}, value)
            end
            RUBY
          else
            class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def load_#{arg_defn.keyword}(value)
              value
            end
            RUBY
          end

          class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def validate_#{arg_defn.keyword}(value)
            # No-op
          end
          RUBY
          arg_defn
        end

        # @api private
        def arguments_loads_as_type
          inherited_lookups = superclass.respond_to?(:arguments_loads_as_type) ? superclass.arguments_loads_as_type : {}
          inherited_lookups.merge(own_arguments_loads_as_type)
        end

        private

        def own_arguments_loads_as_type
          @own_arguments_loads_as_type ||= {}
        end
      end
    end
  end
end
