# frozen_string_literal: true
# test_via: ../object.rb
require "graphql/schema/field/connection_extension"
require "graphql/schema/field/scope_extension"

module GraphQL
  class Schema
    class Field
      include GraphQL::Schema::Member::CachedGraphQLDefinition
      include GraphQL::Schema::Member::AcceptsDefinition
      include GraphQL::Schema::Member::HasArguments
      include GraphQL::Schema::Member::HasPath

      # @return [String] the GraphQL name for this field, camelized unless `camelize: false` is provided
      attr_reader :name
      alias :graphql_name :name

      attr_writer :description

      # @return [String, nil] If present, the field is marked as deprecated with this documentation
      attr_accessor :deprecation_reason

      # @return [Symbol] Method or hash key to look up
      attr_reader :method_sym

      # @return [String] Method or hash key to look up
      attr_reader :method_str

      # @return [Class] The type that this field belongs to
      attr_reader :owner

      # @return [Class, nil] The {Schema::Resolver} this field was derived from, if there is one
      def resolver
        @resolver_class
      end

      alias :mutation :resolver

      # @return [Array<Symbol>]
      attr_reader :extras

      # @return [Boolean] Apply tracing to this field? (Default: skip scalars, this is the override value)
      attr_reader :trace

      # Create a field instance from a list of arguments, keyword arguments, and a block.
      #
      # This method implements prioritization between the `resolver` or `mutation` defaults
      # and the local overrides via other keywords.
      #
      # It also normalizes positional arguments into keywords for {Schema::Field#initialize}.
      # @param resolver [Class] A {GraphQL::Schema::Resolver} class to use for field configuration
      # @param mutation [Class] A {GraphQL::Schema::Mutation} class to use for field configuration
      # @return [GraphQL::Schema:Field] an instance of `self
      # @see {.initialize} for other options
      def self.from_options(name = nil, type = nil, desc = nil, resolver: nil, mutation: nil, **kwargs, &block)
        if (parent_config = resolver || mutation)
          # Get the parent config, merge in local overrides
          kwargs = parent_config.field_options.merge(kwargs)
          # Add a reference to that parent class
          kwargs[:resolver_class] = parent_config
        end

        if name
          kwargs[:name] = name
        end

        if !type.nil?
          if type.is_a?(GraphQL::Field)
            raise ArgumentError, "A GraphQL::Field was passed as the second argument, use the `field:` keyword for this instead."
          end
          if desc
            if kwargs[:description]
              raise ArgumentError, "Provide description as a positional argument or `description:` keyword, but not both (#{desc.inspect}, #{kwargs[:description].inspect})"
            end

            kwargs[:description] = desc
            kwargs[:type] = type
          elsif (kwargs[:field] || kwargs[:function] || resolver || mutation) && type.is_a?(String)
            # The return type should be copied from `field` or `function`, and the second positional argument is the description
            kwargs[:description] = type
          else
            kwargs[:type] = type
          end
        end
        new(**kwargs, &block)
      end

      # Can be set with `connection: true|false` or inferred from a type name ending in `*Connection`
      # @return [Boolean] if true, this field will be wrapped with Relay connection behavior
      def connection?
        if @connection.nil?
          # Provide default based on type name
          return_type_name = if (contains_type = @field || @function)
            Member::BuildType.to_type_name(contains_type.type)
          elsif @return_type_expr
            Member::BuildType.to_type_name(@return_type_expr)
          else
            # As a last ditch, try to force loading the return type:
            type.unwrap.name
          end
          @connection = return_type_name.end_with?("Connection")
        else
          @connection
        end
      end

      # @return [Boolean] if true, the return type's `.scope_items` method will be applied to this field's return value
      def scoped?
        if !@scope.nil?
          # The default was overridden
          @scope
        else
          @return_type_expr.is_a?(Array) || (@return_type_expr.is_a?(String) && @return_type_expr.include?("[")) || connection?
        end
      end

      # @param name [Symbol] The underscore-cased version of this field name (will be camelized for the GraphQL API)
      # @param type [Class, GraphQL::BaseType, Array] The return type of this field
      # @param owner [Class] The type that this field belongs to
      # @param null [Boolean] `true` if this field may return `null`, `false` if it is never `null`
      # @param description [String] Field description
      # @param deprecation_reason [String] If present, the field is marked "deprecated" with this message
      # @param method [Symbol] The method to call to resolve this field (defaults to `name`)
      # @param hash_key [Object] The hash key to lookup to resolve this field (defaults to `name` or `name.to_s`)
      # @param connection [Boolean] `true` if this field should get automagic connection behavior; default is to infer by `*Connection` in the return type name
      # @param max_page_size [Integer] For connections, the maximum number of items to return from this field
      # @param introspection [Boolean] If true, this field will be marked as `#introspection?` and the name may begin with `__`
      # @param resolve [<#call(obj, args, ctx)>] **deprecated** for compatibility with <1.8.0
      # @param field [GraphQL::Field, GraphQL::Schema::Field] **deprecated** for compatibility with <1.8.0
      # @param function [GraphQL::Function] **deprecated** for compatibility with <1.8.0
      # @param resolver_class [Class] (Private) A {Schema::Resolver} which this field was derived from. Use `resolver:` to create a field with a resolver.
      # @param arguments [{String=>GraphQL::Schema::Argument, Hash}] Arguments for this field (may be added in the block, also)
      # @param camelize [Boolean] If true, the field name will be camelized when building the schema
      # @param complexity [Numeric] When provided, set the complexity for this field
      # @param scope [Boolean] If true, the return type's `.scope_items` method will be called on the return value
      # @param subscription_scope [Symbol, String] A key in `context` which will be used to scope subscription payloads
      # @param extensions [Array<Class>] Named extensions to apply to this field (see also {#extension})
      # @param trace [Boolean] If true, a {GraphQL::Tracing} tracer will measure this scalar field
      def initialize(type: nil, name: nil, owner: nil, null: nil, field: nil, function: nil, description: nil, deprecation_reason: nil, method: nil, connection: nil, max_page_size: nil, scope: nil, resolve: nil, introspection: false, hash_key: nil, camelize: true, trace: nil, complexity: 1, extras: [], extensions: [], resolver_class: nil, subscription_scope: nil, arguments: {}, &definition_block)
        if name.nil?
          raise ArgumentError, "missing first `name` argument or keyword `name:`"
        end
        if !(field || function || resolver_class)
          if type.nil?
            raise ArgumentError, "missing second `type` argument or keyword `type:`"
          end
          if null.nil?
            raise ArgumentError, "missing keyword argument null:"
          end
        end
        if (field || function || resolve) && extras.any?
          raise ArgumentError, "keyword `extras:` may only be used with method-based resolve and class-based field such as mutation class, please remove `field:`, `function:` or `resolve:`"
        end
        @name = camelize ? Member::BuildType.camelize(name.to_s) : name.to_s
        @description = description
        if field.is_a?(GraphQL::Schema::Field)
          raise ArgumentError, "Instead of passing a field as `field:`, use `add_field(field)` to add an already-defined field."
        else
          @field = field
        end
        @function = function
        @resolve = resolve
        @deprecation_reason = deprecation_reason
        if method && hash_key
          raise ArgumentError, "Provide `method:` _or_ `hash_key:`, not both. (called with: `method: #{method.inspect}, hash_key: #{hash_key.inspect}`)"
        end

        # TODO: I think non-string/symbol hash keys are wrongly normalized (eg `1` will not work)
        method_name = method || hash_key || Member::BuildType.underscore(name.to_s)

        @method_str = method_name.to_s
        @method_sym = method_name.to_sym
        @complexity = complexity
        @return_type_expr = type
        @return_type_null = null
        @connection = connection
        @max_page_size = max_page_size
        @introspection = introspection
        @extras = extras
        @resolver_class = resolver_class
        @scope = scope
        @trace = trace

        # Override the default from HasArguments
        @own_arguments = {}
        arguments.each do |name, arg|
          if arg.is_a?(Hash)
            argument(name: name, **arg)
          else
            @own_arguments[name] = arg
          end
        end

        @owner = owner
        @subscription_scope = subscription_scope

        # Do this last so we have as much context as possible when initializing them:
        @extensions = []
        if extensions.any?
          self.extensions(extensions)
        end
        # This should run before connection extension,
        # but should it run after the definition block?
        if scoped?
          self.extension(ScopeExtension)
        end
        # The problem with putting this after the definition_block
        # is that it would override arguments
        if connection?
          self.extension(ConnectionExtension)
        end

        if definition_block
          if definition_block.arity == 1
            yield self
          else
            instance_eval(&definition_block)
          end
        end
      end

      # @param text [String]
      # @return [String]
      def description(text = nil)
        if text
          @description = text
        else
          @description
        end
      end

      # Read extension instances from this field,
      # or add new classes/options to be initialized on this field.
      #
      # @param extensions [Array<Class>, Hash<Class => Object>] Add extensions to this field
      # @return [Array<GraphQL::Schema::FieldExtension>] extensions to apply to this field
      def extensions(new_extensions = nil)
        if new_extensions.nil?
          # Read the value
          @extensions
        else
          if @resolve || @function
            raise ArgumentError, <<-MSG
Extensions are not supported with resolve procs or functions,
but #{owner.name}.#{name} has: #{@resolve || @function}
So, it can't have extensions: #{extensions}.
Use a method or a Schema::Resolver instead.
MSG
          end

          # Normalize to a Hash of {name => options}
          extensions_with_options = if new_extensions.last.is_a?(Hash)
            new_extensions.pop
          else
            {}
          end
          new_extensions.each do |f|
            extensions_with_options[f] = nil
          end

          # Initialize each class and stash the instance
          extensions_with_options.each do |extension_class, options|
            @extensions << extension_class.new(field: self, options: options)
          end
        end
      end

      # Add `extension` to this field, initialized with `options` if provided.
      # @param extension [Class] subclass of {Schema::Fieldextension}
      # @param options [Object] if provided, given as `options:` when initializing `extension`.
      def extension(extension, options = nil)
        extensions([{extension => options}])
      end

      def complexity(new_complexity)
        case new_complexity
        when Proc
          if new_complexity.parameters.size != 3
            fail(
              "A complexity proc should always accept 3 parameters: ctx, args, child_complexity. "\
              "E.g.: complexity ->(ctx, args, child_complexity) { child_complexity * args[:limit] }"
            )
          else
            @complexity = new_complexity
          end
        when Numeric
          @complexity = new_complexity
        else
          raise("Invalid complexity: #{new_complexity.inspect} on #{@name}")
        end
      end

      # @return [Integer, nil] Applied to connections if present
      attr_reader :max_page_size

      # @return [GraphQL::Field]
      def to_graphql
        field_defn = if @field
          @field.dup
        elsif @function
          GraphQL::Function.build_field(@function)
        else
          GraphQL::Field.new
        end

        field_defn.name = @name
        if @return_type_expr
          field_defn.type = -> { type }
        end

        if @description
          field_defn.description = @description
        end

        if @deprecation_reason
          field_defn.deprecation_reason = @deprecation_reason
        end

        if @resolver_class
          if @resolver_class < GraphQL::Schema::Mutation
            field_defn.mutation = @resolver_class
          end
          field_defn.metadata[:resolver] = @resolver_class
        end

        if !@trace.nil?
          field_defn.trace = @trace
        end

        field_defn.resolve = self.method(:resolve_field)
        field_defn.connection = connection?
        field_defn.connection_max_page_size = max_page_size
        field_defn.introspection = @introspection
        field_defn.complexity = @complexity
        field_defn.subscription_scope = @subscription_scope

        arguments.each do |name, defn|
          arg_graphql = defn.to_graphql
          field_defn.arguments[arg_graphql.name] = arg_graphql
        end

        # Support a passed-in proc, one way or another
        @resolve_proc = if @resolve
          @resolve
        elsif @function
          @function
        elsif @field
          @field.resolve_proc
        end

        # Ok, `self` isn't a class, but this is for consistency with the classes
        field_defn.metadata[:type_class] = self

        field_defn
      end

      def type
        @type ||= Member::BuildType.parse_type(@return_type_expr, null: @return_type_null)
      rescue
        raise ArgumentError, "Failed to build return type for #{@owner.graphql_name}.#{name} from #{@return_type_expr.inspect}: #{$!.message}", $!.backtrace
      end

      def visible?(context)
        if @resolver_class
          @resolver_class.visible?(context)
        else
          true
        end
      end

      def accessible?(context)
        if @resolver_class
          @resolver_class.accessible?(context)
        else
          true
        end
      end

      def authorized?(object, context)
        self_auth = if @resolver_class
          @resolver_class.authorized?(object, context)
        else
          true
        end

        self_auth && arguments.each_value.all? { |a| a.authorized?(object, context) }
      end

      # Implement {GraphQL::Field}'s resolve API.
      #
      # Eventually, we might hook up field instances to execution in another way. TBD.
      def resolve_field(obj, args, ctx)
        ctx.schema.after_lazy(obj) do |after_obj|
          # First, apply auth ...
          query_ctx = ctx.query.context
          # TODO this is for introspection, since it doesn't self-wrap anymore
          # inner_obj = after_obj.respond_to?(:object) ? after_obj.object : after_obj
          inner_obj = after_obj && after_obj.object
          if authorized?(inner_obj, query_ctx)
            # Then if it passed, resolve the field
            if @resolve_proc
              # Might be nil, still want to call the func in that case
              @resolve_proc.call(inner_obj, args, ctx)
            else
              public_send_field(after_obj, args, ctx)
            end
          else
            nil
          end
        end
      end

      # Called by interpreter
      # TODO rename this, make it public-ish
      def resolve_field_2(obj_or_lazy, args, ctx)
        if @resolve_proc
          raise "Can't run resolve proc for #{path} when using GraphQL::Execution::Interpreter"
        end
        begin
          ctx.schema.after_lazy(obj_or_lazy) do |obj|
            application_object = obj.object
            if self.authorized?(application_object, ctx)
              with_extensions(obj, args, ctx) do |extended_obj, extended_args|
                field_receiver = if @resolver_class
                  resolver_obj = if extended_obj.is_a?(GraphQL::Schema::Object)
                    extended_obj.object
                  else
                    extended_obj
                  end
                  @resolver_class.new(object: resolver_obj, context: ctx)
                else
                  extended_obj
                end

                if extended_args.any?
                  field_receiver.public_send(method_sym, extended_args)
                else
                  field_receiver.public_send(method_sym)
                end
              end
            end
          end
        rescue GraphQL::UnauthorizedError => err
          ctx.schema.unauthorized_object(err)
        end
      rescue GraphQL::ExecutionError => err
        err
      end

      # Find a way to resolve this field, checking:
      #
      # - Hash keys, if the wrapped object is a hash;
      # - A method on the wrapped object;
      # - Or, raise not implemented.
      #
      # This can be overridden by defining a method on the object type.
      # @param obj [GraphQL::Schema::Object]
      # @param ruby_kwargs [Hash<Symbol => Object>]
      # @param ctx [GraphQL::Query::Context]
      def resolve_field_method(obj, ruby_kwargs, ctx)
        if obj.object.is_a?(Hash)
          inner_object = obj.object
          if inner_object.key?(@method_sym)
            inner_object[@method_sym]
          else
            inner_object[@method_str]
          end
        elsif obj.object.respond_to?(@method_sym)
          if ruby_kwargs.any?
            obj.object.public_send(@method_sym, **ruby_kwargs)
          else
            obj.object.public_send(@method_sym)
          end
        else
          raise <<-ERR
        Failed to implement #{@owner.graphql_name}.#{@name}, tried:

        - `#{obj.class}##{@method_sym}`, which did not exist
        - `#{obj.object.class}##{@method_sym}`, which did not exist
        - Looking up hash key `#{@method_sym.inspect}` or `#{@method_str.inspect}` on `#{obj.object}`, but it wasn't a Hash

        To implement this field, define one of the methods above (and check for typos)
        ERR
        end
      end

      private

      NO_ARGS = {}.freeze

      def public_send_field(obj, graphql_args, field_ctx)
        if graphql_args.any? || @extras.any?
          # Splat the GraphQL::Arguments to Ruby keyword arguments
          ruby_kwargs = graphql_args.to_kwargs
          # Apply any `prepare` methods. Not great code organization, can this go somewhere better?
          arguments.each do |name, arg_defn|
            ruby_kwargs_key = arg_defn.keyword
            if ruby_kwargs.key?(ruby_kwargs_key) && arg_defn.prepare
              ruby_kwargs[ruby_kwargs_key] = arg_defn.prepare_value(obj, ruby_kwargs[ruby_kwargs_key])
            end
          end

          @extras.each do |extra_arg|
            # TODO: provide proper tests for `:ast_node`, `:irep_node`, `:parent`, others?
            ruby_kwargs[extra_arg] = field_ctx.public_send(extra_arg)
          end
        else
          ruby_kwargs = NO_ARGS
        end

        query_ctx = field_ctx.query.context
        with_extensions(obj, ruby_kwargs, query_ctx) do |extended_obj, extended_args|
          if @resolver_class
            if extended_obj.is_a?(GraphQL::Schema::Object)
              extended_obj = extended_obj.object
            end
            extended_obj = @resolver_class.new(object: extended_obj, context: query_ctx)
          end

          if extended_args.any?
            extended_obj.public_send(@method_sym, **extended_args)
          else
            extended_obj.public_send(@method_sym)
          end
        end
      end

      # Wrap execution with hooks.
      # Written iteratively to avoid big stack traces.
      # @return [Object] Whatever the
      def with_extensions(obj, args, ctx)
        if @extensions.none?
          yield(obj, args)
        else
          # Save these so that the originals can be re-given to `after_resolve` handlers.
          original_args = args
          original_obj = obj

          memos = []
          @extensions.each do |ext|
            ext.before_resolve(object: obj, arguments: args, context: ctx) do |extended_obj, extended_args, memo|
              # update this scope with the yielded value
              obj = extended_obj
              args = extended_args
              # record the memo (or nil if none was yielded)
              memos << memo
            end
          end
          # Call the block which actually calls resolve
          value = yield(obj, args)

          ctx.schema.after_lazy(value) do |resolved_value|
            @extensions.each_with_index do |ext, idx|
              memo = memos[idx]
              # TODO after_lazy?
              resolved_value = ext.after_resolve(object: original_obj, arguments: original_args, context: ctx, value: resolved_value, memo: memo)
            end
            resolved_value
          end
        end
      end
    end
  end
end
