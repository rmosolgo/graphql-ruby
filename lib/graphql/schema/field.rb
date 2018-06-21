# frozen_string_literal: true
# test_via: ../object.rb
module GraphQL
  class Schema
    class Field
      include GraphQL::Schema::Member::CachedGraphQLDefinition
      include GraphQL::Schema::Member::AcceptsDefinition
      include GraphQL::Schema::Member::HasArguments

      # @return [String] the GraphQL name for this field, camelized unless `camelize: false` is provided
      attr_reader :name
      alias :graphql_name :name

      # @return [String]
      attr_accessor :description

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

      # @param name [Symbol] The underscore-cased version of this field name (will be camelized for the GraphQL API)
      # @param return_type_expr [Class, GraphQL::BaseType, Array] The return type of this field
      # @param desc [String] Field description
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
      # @param subscription_scope [Symbol, String] A key in `context` which will be used to scope subscription payloads
      def initialize(type: nil, name: nil, owner: nil, null: nil, field: nil, function: nil, description: nil, deprecation_reason: nil, method: nil, connection: nil, max_page_size: nil, resolve: nil, introspection: false, hash_key: nil, camelize: true, complexity: 1, extras: [], resolver_class: nil, subscription_scope: nil, arguments: {}, &definition_block)

        if name.nil?
          raise ArgumentError, "missing first `name` argument or keyword `name:`"
        end
        if !(field || function || mutation || resolver)
          if type.nil?
            raise ArgumentError, "missing second `type` argument or keyword `type:`"
          end
          if null.nil?
            raise ArgumentError, "missing keyword argument null:"
          end
        end
        if (field || function || resolve || mutation) && extras.any?
          raise ArgumentError, "keyword `extras:` may only be used with method-based resolve, please remove `field:`, `function:`, `resolve:`, or `mutation:`"
        end
        @name = camelize ? Member::BuildType.camelize(name.to_s) : name.to_s
        @description = description
        if field.is_a?(GraphQL::Schema::Field)
          @field_instance = field
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

        if definition_block
          instance_eval(&definition_block)
        end
      end

      def description(text = nil)
        if text
          @description = text
        else
          @description
        end
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

      # @return [GraphQL::Field]
      def to_graphql
        # this field was previously defined and passed here, so delegate to it
        if @field_instance
          return @field_instance.to_graphql
        end


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

        if @connection.nil?
          # Provide default based on type name
          return_type_name = if @field || @function
            Member::BuildType.to_type_name(field_defn.type)
          elsif @return_type_expr
            Member::BuildType.to_type_name(@return_type_expr)
          else
            raise "No connection info possible"
          end
          @connection = return_type_name.end_with?("Connection")
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

        field_defn.resolve = self.method(:resolve_field)
        field_defn.connection = @connection
        field_defn.connection_max_page_size = @max_page_size
        field_defn.introspection = @introspection
        field_defn.complexity = @complexity
        field_defn.subscription_scope = @subscription_scope

        # apply this first, so it can be overriden below
        if @connection
          # TODO: this could be a bit weird, because these fields won't be present
          # after initialization, only in the `to_graphql` response.
          # This calculation _could_ be moved up if need be.
          argument :after, "String", "Returns the elements in the list that come after the specified cursor.", required: false
          argument :before, "String", "Returns the elements in the list that come before the specified cursor.", required: false
          argument :first, "Int", "Returns the first _n_ elements from the list.", required: false
          argument :last, "Int", "Returns the last _n_ elements from the list.", required: false
        end

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
        if @resolver_class
          @resolver_class.authorized?(object, context)
        else
          true
        end
      end

      # Implement {GraphQL::Field}'s resolve API.
      #
      # Eventually, we might hook up field instances to execution in another way. TBD.
      def resolve_field(obj, args, ctx)
        ctx.schema.after_lazy(obj) do |after_obj|
          # First, apply auth ...
          query_ctx = ctx.query.context
          inner_obj = after_obj && after_obj.object
          if authorized?(inner_obj, query_ctx) && arguments.each_value.all? { |a| a.authorized?(inner_obj, query_ctx) }
            # Then if it passed, resolve the field
            if @resolve_proc
              # Might be nil, still want to call the func in that case
              @resolve_proc.call(inner_obj, args, ctx)
            elsif @resolver_class
              singleton_inst = @resolver_class.new(object: inner_obj, context: query_ctx)
              public_send_field(singleton_inst, args, ctx)
            else
              public_send_field(after_obj, args, ctx)
            end
          else
            nil
          end
        end
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

          if @connection
            # Remove pagination args before passing it to a user method
            ruby_kwargs.delete(:first)
            ruby_kwargs.delete(:last)
            ruby_kwargs.delete(:before)
            ruby_kwargs.delete(:after)
          end

          @extras.each do |extra_arg|
            # TODO: provide proper tests for `:ast_node`, `:irep_node`, `:parent`, others?
            ruby_kwargs[extra_arg] = field_ctx.public_send(extra_arg)
          end
        else
          ruby_kwargs = NO_ARGS
        end


        if ruby_kwargs.any?
          obj.public_send(@method_sym, **ruby_kwargs)
        else
          obj.public_send(@method_sym)
        end
      end
    end
  end
end
