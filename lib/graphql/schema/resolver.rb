# frozen_string_literal: true
require "graphql/schema/resolver/has_payload_type"

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
      extend GraphQL::Schema::Member::HasValidators
      include Schema::Member::HasPath
      extend Schema::Member::HasPath

      # @param object [Object] the initialize object, pass to {Query.initialize} as `root_value`
      # @param context [GraphQL::Query::Context]
      # @param field [GraphQL::Schema::Field]
      def initialize(object:, context:, field:)
        @object = object
        @context = context
        @field = field
        # Since this hash is constantly rebuilt, cache it for this call
        @arguments_by_keyword = {}
        self.class.arguments.each do |name, arg|
          @arguments_by_keyword[arg.keyword] = arg
        end
        @arguments_loads_as_type = self.class.arguments_loads_as_type
        @prepared_arguments = nil
      end

      # @return [Object] The application object this field is being resolved on
      attr_reader :object

      # @return [GraphQL::Query::Context]
      attr_reader :context

      # @return [GraphQL::Dataloader]
      def dataloader
        context.dataloader
      end

      # @return [GraphQL::Schema::Field]
      attr_reader :field

      def arguments
        @prepared_arguments || raise("Arguments have not been prepared yet, still waiting for #load_arguments to resolve. (Call `.arguments` later in the code.)")
      end

      # This method is _actually_ called by the runtime,
      # it does some preparation and then eventually calls
      # the user-defined `#resolve` method.
      # @api private
      def resolve_with_support(**args)
        # First call the ready? hook which may raise
        ready_val = if args.any?
          ready?(**args)
        else
          ready?
        end
        context.schema.after_lazy(ready_val) do |is_ready, ready_early_return|
          if ready_early_return
            if is_ready != false
              raise "Unexpected result from #ready? (expected `true`, `false` or `[false, {...}]`): [#{authorized_result.inspect}, #{ready_early_return.inspect}]"
            else
              ready_early_return
            end
          elsif is_ready
            # Then call each prepare hook, which may return a different value
            # for that argument, or may return a lazy object
            load_arguments_val = load_arguments(args)
            context.schema.after_lazy(load_arguments_val) do |loaded_args|
              @prepared_arguments = loaded_args
              Schema::Validator.validate!(self.class.validators, object, context, loaded_args, as: @field)
              # Then call `authorized?`, which may raise or may return a lazy object
              authorized_val = if loaded_args.any?
                authorized?(**loaded_args)
              else
                authorized?
              end
              context.schema.after_lazy(authorized_val) do |(authorized_result, early_return)|
                # If the `authorized?` returned two values, `false, early_return`,
                # then use the early return value instead of continuing
                if early_return
                  if authorized_result == false
                    early_return
                  else
                    raise "Unexpected result from #authorized? (expected `true`, `false` or `[false, {...}]`): [#{authorized_result.inspect}, #{early_return.inspect}]"
                  end
                elsif authorized_result
                  # Finally, all the hooks have passed, so resolve it
                  if loaded_args.any?
                    public_send(self.class.resolve_method, **loaded_args)
                  else
                    public_send(self.class.resolve_method)
                  end
                else
                  nil
                end
              end
            end
          end
        end
      end

      # Do the work. Everything happens here.
      # @return [Object] An object corresponding to the return type
      def resolve(**args)
        raise GraphQL::RequiredImplementationMissingError, "#{self.class.name}#resolve should execute the field's logic"
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
      # @return [Boolean, early_return_data] If `false`, execution will stop (and `early_return_data` will be returned instead, if present.)
      def ready?(**args)
        true
      end

      # Called after arguments are loaded, but before resolving.
      #
      # Override it to check everything before calling the mutation.
      # @param inputs [Hash] The input arguments
      # @raise [GraphQL::ExecutionError] To add an error to the response
      # @raise [GraphQL::UnauthorizedError] To signal an authorization failure
      # @return [Boolean, early_return_data] If `false`, execution will stop (and `early_return_data` will be returned instead, if present.)
      def authorized?(**inputs)
        self.class.arguments.each_value do |argument|
          arg_keyword = argument.keyword
          if inputs.key?(arg_keyword) && !(arg_value = inputs[arg_keyword]).nil? && (arg_value != argument.default_value)
            arg_auth, err = argument.authorized?(self, arg_value, context)
            if !arg_auth
              return arg_auth, err
            else
              true
            end
          else
            true
          end
        end
      end

      private

      def load_arguments(args)
        prepared_args = {}
        prepare_lazies = []

        args.each do |key, value|
          arg_defn = @arguments_by_keyword[key]
          if arg_defn
            if value.nil?
              prepared_args[key] = value
            else
              prepped_value = prepared_args[key] = load_argument(key, value)
              if context.schema.lazy?(prepped_value)
                prepare_lazies << context.schema.after_lazy(prepped_value) do |finished_prepped_value|
                  prepared_args[key] = finished_prepped_value
                end
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
        # @param new_type [Class, Array<Class>, nil] If a type definition class is provided, it will be used as the return type of the field
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

        def broadcastable(new_broadcastable)
          @broadcastable = new_broadcastable
        end

        # @return [Boolean, nil]
        def broadcastable?
          if defined?(@broadcastable)
            @broadcastable
          else
            (superclass.respond_to?(:broadcastable?) ? superclass.broadcastable? : nil)
          end
        end

        # Get or set the `max_page_size:` which will be configured for fields using this resolver
        # (`nil` means "unlimited max page size".)
        # @param max_page_size [Integer, nil] Set a new value
        # @return [Integer, nil] The `max_page_size` assigned to fields that use this resolver
        def max_page_size(new_max_page_size = :not_given)
          if new_max_page_size != :not_given
            @max_page_size = new_max_page_size
          elsif defined?(@max_page_size)
            @max_page_size
          elsif superclass.respond_to?(:max_page_size)
            superclass.max_page_size
          else
            nil
          end
        end

        # @return [Boolean] `true` if this resolver or a superclass has an assigned `max_page_size`
        def has_max_page_size?
          defined?(@max_page_size) || (superclass.respond_to?(:has_max_page_size?) && superclass.has_max_page_size?)
        end

        def field_options
          field_opts = {
            type: type_expr,
            description: description,
            extras: extras,
            resolver_method: :resolve_with_support,
            resolver_class: self,
            arguments: arguments,
            null: null,
            complexity: complexity,
            extensions: extensions,
            broadcastable: broadcastable?,
          }

          if has_max_page_size?
            field_opts[:max_page_size] = max_page_size
          end

          field_opts
        end

        # A non-normalized type configuration, without `null` applied
        def type_expr
          @type_expr || (superclass.respond_to?(:type_expr) ? superclass.type_expr : nil)
        end

        # Add an argument to this field's signature, but
        # also add some preparation hook methods which will be used for this argument
        # @see {GraphQL::Schema::Argument#initialize} for the signature
        def argument(*args, **kwargs, &block)
          loads = kwargs[:loads]
          # Use `from_resolver: true` to short-circuit the InputObject's own `loads:` implementation
          # so that we can support `#load_{x}` methods below.
          arg_defn = super(*args, from_resolver: true, **kwargs)
          own_arguments_loads_as_type[arg_defn.keyword] = loads if loads

          if loads && arg_defn.type.list?
            class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def load_#{arg_defn.keyword}(values)
              argument = @arguments_by_keyword[:#{arg_defn.keyword}]
              lookup_as_type = @arguments_loads_as_type[:#{arg_defn.keyword}]
              context.schema.after_lazy(values) do |values2|
                GraphQL::Execution::Lazy.all(values2.map { |value| load_application_object(argument, lookup_as_type, value, context) })
              end
            end
            RUBY
          elsif loads
            class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def load_#{arg_defn.keyword}(value)
              argument = @arguments_by_keyword[:#{arg_defn.keyword}]
              lookup_as_type = @arguments_loads_as_type[:#{arg_defn.keyword}]
              load_application_object(argument, lookup_as_type, value, context)
            end
            RUBY
          else
            class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def load_#{arg_defn.keyword}(value)
              value
            end
            RUBY
          end

          arg_defn
        end

        # @api private
        def arguments_loads_as_type
          inherited_lookups = superclass.respond_to?(:arguments_loads_as_type) ? superclass.arguments_loads_as_type : {}
          inherited_lookups.merge(own_arguments_loads_as_type)
        end

        # Registers new extension
        # @param extension [Class] Extension class
        # @param options [Hash] Optional extension options
        def extension(extension, **options)
          extensions << {extension => options}
        end

        # @api private
        def extensions
          @extensions ||= []
        end

        private

        def own_arguments_loads_as_type
          @own_arguments_loads_as_type ||= {}
        end
      end
    end
  end
end
