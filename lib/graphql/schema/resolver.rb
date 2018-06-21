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
        before_prepare_val = if args.any?
          before_prepare(**args)
        else
          before_prepare
        end
        context.schema.after_lazy(before_prepare_val) do
          prepare_val = prepare(args)
          context.schema.after_lazy(prepare_val) do |prepared_args|
            if prepared_args.any?
              public_send(self.class.resolve_method, **prepared_args)
            else
              public_send(self.class.resolve_method)
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

      def prepare(args)
        prepared_args = {}
        arg_defns = self.class.arguments

        args.each do |key, value|
          if arg_defns.key?(key.to_s)
            prepared_args[key] = prepare_argument(key, value)
          else
            # These are `extras: [...]`
            prepared_args[key] = value
          end
        end

        prepare_lazies = []
        prepared_args.each do |key, prepped_value|
          if context.schema.lazy?(prepped_value)
            prepare_lazies << context.schema.after_lazy(prepped_value) do |finished_prepped_value|
              prepared_args[key] = finished_prepped_value
            end
          end
        end

        # Avoid returning a lazy if none are needed
        if prepare_lazies.any?
          GraphQL::Execution::Lazy.all(prepare_lazies).then { prepared_args }
        else
          prepared_args
        end
      end

      def prepare_argument(name, value)
        public_send("prepare_#{name}", value)
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
        # also add a `prepare_#{name}` method which will be used for this argument
        # @see {GraphQL::Schema::Argument#initialize} for the signature
        def argument(*)
          arg_defn = super
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def prepare_#{arg_defn.keyword}(value)
            value
          end
          RUBY
          arg_defn
        end
      end
    end
  end
end
