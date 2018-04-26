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

      # @return [String]
      attr_accessor :description

      # @return [Symbol] Method or hash key to look up
      attr_reader :method_sym

      # @return [String] Method or hash key to look up
      attr_reader :method_str

      # @return [Class] The type that this field belongs to
      attr_reader :owner

      # @return [Class, nil] The mutation this field was derived from, if there is one
      def mutation
        @mutation || @mutation_class
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
      # @param definition_directives [Hash<String => Nil, Hash<String=>Any>>] Directives to include in the SDL print-out of this field
      # @param introspection [Boolean] If true, this field will be marked as `#introspection?` and the name may begin with `__`
      # @param resolve [<#call(obj, args, ctx)>] **deprecated** for compatibility with <1.8.0
      # @param field [GraphQL::Field, GraphQL::Schema::Field] **deprecated** for compatibility with <1.8.0
      # @param function [GraphQL::Function] **deprecated** for compatibility with <1.8.0
      # @param mutation [Class] A {Schema::Mutation} class for serving this field
      # @param mutation_class [Class] (Private) A {Schema::Mutation} which this field was derived from.
      # @param arguments [{String=>GraphQL::Schema::Arguments}] Arguments for this field (may be added in the block, also)
      # @param camelize [Boolean] If true, the field name will be camelized when building the schema
      # @param complexity [Numeric] When provided, set the complexity for this field
      def initialize(name, return_type_expr = nil, desc = nil,
          owner: nil,
          null: nil,
          field: nil,
          function: nil,
          description: nil,
          deprecation_reason: nil,
          method: nil,
          connection: nil,
          max_page_size: nil,
          resolve: nil,
          introspection: false,
          hash_key: nil,
          camelize: true,
          complexity: 1,
          extras: [],
          mutation: nil,
          definition_directives: [],
          mutation_class: nil,
          arguments: {}
        )
        if (field || function) && desc.nil? && return_type_expr.is_a?(String)
          # The return type should be copied from `field` or `function`, and the second positional argument is the description
          desc = return_type_expr
          return_type_expr = nil
        end
        if mutation && (return_type_expr || desc || description || function || field || !null.nil? || deprecation_reason || method || resolve || introspection || hash_key)
          raise ArgumentError, "when keyword `mutation:` is present, all arguments are ignored, please remove them"
        end
        if !(field || function || mutation)
          if return_type_expr.nil?
            raise ArgumentError, "missing positional argument `type`"
          end
          if null.nil?
            raise ArgumentError, "missing keyword argument null:"
          end
        end
        if (field || function || resolve || resolve) && extras.any?
          raise ArgumentError, "keyword `extras:` may only be used with method-based resolve, please remove `field:`, `function:`, `resolve:`, or `mutation:`"
        end
        if return_type_expr.is_a?(GraphQL::Field)
          raise ArgumentError, "A GraphQL::Field was passed as the second argument, use the `field:` keyword for this instead."
        end
        @name = camelize ? Member::BuildType.camelize(name.to_s) : name.to_s
        if description && desc
          raise ArgumentError, "Provide description as a positional argument or `description:` keyword, but not both (#{desc.inspect}, #{description.inspect})"
        end
        @description = description || desc
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
        @return_type_expr = return_type_expr
        @return_type_null = null
        @connection = connection
        @max_page_size = max_page_size
        @introspection = introspection
        @extras = extras
        @mutation = mutation
        @mutation_class = mutation_class
        # Override the default from HasArguments
        @own_arguments = arguments
        @owner = owner
        @definition_directives = definition_directives

        if block_given?
          instance_eval(&Proc.new)
        end
      end

      def description(text = nil)
        if text
          @description = text
        else
          @description
        end
      end

      # @return [Hash<String => Nil, Hash<String=>Any>>] Directives to print in this field's SDL print-out
      def definition_directives(new_directives = nil)
        if new_directives
          @definition_directives = new_directives
        end
        @definition_directives
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
        elsif @mutation
          field_inst = @mutation.graphql_field
          return field_inst.to_graphql
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

        if @mutation_class
          field_defn.mutation = @mutation_class
        end

        field_defn.resolve = self.method(:resolve_field)
        field_defn.connection = @connection
        field_defn.connection_max_page_size = @max_page_size
        field_defn.introspection = @introspection
        field_defn.complexity = @complexity

        # apply this first, so it can be overriden below
        if @connection
          # TODO: this could be a bit weird, because these fields won't be present
          # after initialization, only in the `to_graphql` response.
          # This calculation _could_ be moved up if need be.
          argument :after, "String", "Returns the elements in the list that come after the specified global ID.", required: false
          argument :before, "String", "Returns the elements in the list that come before the specified global ID.", required: false
          argument :first, "Int", "Returns the first _n_ elements from the list.", required: false
          argument :last, "Int", "Returns the last _n_ elements from the list.", required: false
        end

        arguments.each do |name, defn|
          arg_graphql = defn.to_graphql
          field_defn.arguments[arg_graphql.name] = arg_graphql
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

      # Implement {GraphQL::Field}'s resolve API.
      #
      # Eventually, we might hook up field instances to execution in another way. TBD.
      def resolve_field(obj, args, ctx)
        if @resolve || @function || @field
          # Support a passed-in proc, one way or another
          prev_resolve = if @resolve
            @resolve
          elsif @function
            @function
          elsif @field
            @field.resolve_proc
          end

          # Might be nil, still want to call the func in that case
          inner_obj = obj && obj.object
          prev_resolve.call(inner_obj, args, ctx)
        else
          public_send_field(obj, @method_sym, args, ctx)
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

      def public_send_field(obj, method_name, graphql_args, field_ctx)
        if graphql_args.any? || @extras.any?
          # Splat the GraphQL::Arguments to Ruby keyword arguments
          ruby_kwargs = graphql_args.to_kwargs

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
          obj.public_send(method_name, **ruby_kwargs)
        else
          obj.public_send(method_name)
        end
      end
    end
  end
end
