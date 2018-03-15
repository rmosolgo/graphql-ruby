# frozen_string_literal: true
# test_via: ../object.rb
require "graphql/schema/field/dynamic_resolve"
require "graphql/schema/field/unwrapped_resolve"
module GraphQL
  class Schema
    class Field
      include GraphQL::Schema::Member::CachedGraphQLDefinition
      include GraphQL::Schema::Member::HasArguments
      # @return [String]
      attr_reader :name

      # @return [String]
      attr_accessor :description

      # @return [Symbol]
      attr_reader :method

      # @return [Class] The type that this field belongs to
      attr_reader :owner

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
      # @param mutation [Class] A {Schema::Mutation} class for serving this field
      # @param arguments [{String=>GraphQL::Schema::Arguments}] Arguments for this field (may be added in the block, also)
      # @param camelize [Boolean] If true, the field name will be camelized when building the schema
      # @param complexity [Numeric] When provided, set the complexity for this field
      def initialize(name, return_type_expr = nil, desc = nil, owner: nil, null: nil, field: nil, function: nil, description: nil, deprecation_reason: nil, method: nil, connection: nil, max_page_size: nil, resolve: nil, introspection: false, hash_key: nil, camelize: true, complexity: 1, extras: [], mutation: nil, arguments: {}, &definition_block)
        if (field || function) && desc.nil? && return_type_expr.is_a?(String)
          # The return type should be copied from `field` or `function`, and the second positional argument is the description
          desc = return_type_expr
          return_type_expr = nil
        end
        if !(field || function || mutation)
          if return_type_expr.nil?
            raise ArgumentError, "missing positional argument `type`"
          end
          if null.nil?
            raise ArgumentError, "missing keyword argument null:"
          end
        end
        if (field || function || resolve || mutation) && extras.any?
          raise ArgumentError, "keyword `extras:` may only be used with method-based resolve, please remove `field:`, `function:`, or `resolve:`"
        end
        @name = name.to_s
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
        @method = method
        @hash_key = hash_key
        @complexity = complexity
        @return_type_expr = return_type_expr
        @return_type_null = null
        @connection = connection
        @max_page_size = max_page_size
        @introspection = introspection
        @extras = extras
        @camelize = camelize
        @mutation = mutation
        # Override the default from HasArguments
        @own_arguments = arguments
        @owner = owner

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
        elsif @mutation
          return @mutation.graphql_field.to_graphql
        end

        method_name = @method || @hash_key || Member::BuildType.underscore(@name)

        field_defn = if @field
          @field.dup
        elsif @function
          GraphQL::Function.build_field(@function)
        else
          GraphQL::Field.new
        end

        field_defn.name = @camelize ? Member::BuildType.camelize(name) : name
        if @return_type_expr
          return_type_name = Member::BuildType.to_type_name(@return_type_expr)
          connection = @connection.nil? ? return_type_name.end_with?("Connection") : @connection
          field_defn.type = -> {
            begin
              Member::BuildType.parse_type(@return_type_expr, null: @return_type_null)
            rescue
              # TODO: add owner type here
              raise ArgumentError, "Failed to build return type for ??.#{name}: #{$!.message}", $!.backtrace
            end
          }
        elsif @connection.nil? && (@field || @function)
          return_type_name = Member::BuildType.to_type_name(field_defn.type)
          connection = return_type_name.end_with?("Connection")
        else
          connection = @connection
        end

        if @description
          field_defn.description = @description
        end

        if @deprecation_reason
          field_defn.deprecation_reason = @deprecation_reason
        end

        field_defn.resolve = if @resolve || @function || @field
          prev_resolve = @resolve || field_defn.resolve_proc
          UnwrappedResolve.new(inner_resolve: prev_resolve)
        else
          DynamicResolve.new(
            method_name: method_name,
            connection: connection,
            extras: @extras
          )
        end

        field_defn.connection = connection
        field_defn.connection_max_page_size = @max_page_size
        field_defn.introspection = @introspection
        field_defn.complexity = @complexity

        # apply this first, so it can be overriden below
        if connection
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

        field_defn
      end
    end
  end
end
