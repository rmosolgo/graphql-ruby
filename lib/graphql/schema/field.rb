# frozen_string_literal: true
# test_via: ../object.rb
require "graphql/schema/field/dynamic_resolve"
require "graphql/schema/field/unwrapped_resolve"
module GraphQL
  class Schema
    class Field
      include GraphQL::Schema::Member::CachedGraphQLDefinition

      # @return [String]
      attr_reader :name

      # @return [String]
      attr_accessor :description

      # @return [Hash{String => GraphQL::Schema::Argument}]
      attr_reader :arguments

      # @return [Symbol]
      attr_reader :method

      def initialize(name, return_type_expr = nil, desc = nil, null: nil, field: nil, function: nil, description: nil, deprecation_reason: nil, method: nil, connection: nil, max_page_size: nil, resolve: nil, introspection: false, hash_key: nil, extras: [], &definition_block)
        if !(field || function)
          if return_type_expr.nil?
            raise ArgumentError, "missing positional argument `type`"
          end
          if null.nil?
            raise ArgumentError, "missing keyword argument null:"
          end
        end
        if (field || function || resolve) && extras.any?
          raise ArgumentError, "keyword `extras:` may only be used with method-based resolve, please remove `field:`, `function:`, or `resolve:`"
        end
        @name = name.to_s
        if description && desc
          raise ArgumentError, "Provide description as a positional argument or `description:` keyword, but not both (#{desc.inspect}, #{description.inspect})"
        end
        @description = description || desc
        @field = field
        @function = function
        @resolve = resolve
        @deprecation_reason = deprecation_reason
        if method && hash_key
          raise ArgumentError, "Provide `method:` _or_ `hash_key:`, not both. (called with: `method: #{method.inspect}, hash_key: #{hash_key.inspect}`)"
        end
        @method = method
        @hash_key = hash_key
        @return_type_expr = return_type_expr
        @return_type_null = null
        @connection = connection
        @max_page_size = max_page_size
        @introspection = introspection
        @extras = extras
        @arguments = {}

        if definition_block
          instance_eval(&definition_block)
        end
      end

      # This is the `argument(...)` DSL for class-based field definitons
      def argument(*args)
        arg_defn = self.class.argument_class.new(*args)
        arguments[arg_defn.name] = arg_defn
      end

      def description(text = nil)
        if text
          @description = text
        else
          @description
        end
      end

      # @return [GraphQL::Field]
      def to_graphql
        method_name = @method || @hash_key || Member::BuildType.underscore(@name)

        field_defn = if @field
          @field.dup
        elsif @function
          GraphQL::Function.build_field(@function)
        else
          GraphQL::Field.new
        end

        field_defn.name = Member::BuildType.camelize(name)
        if @return_type_expr
          return_type_name = Member::BuildType.to_type_name(@return_type_expr)
          connection = @connection.nil? ? return_type_name.end_with?("Connection") : @connection
          field_defn.type = -> {
            Member::BuildType.parse_type(@return_type_expr, null: @return_type_null)
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

        @arguments.each do |name, defn|
          arg_graphql = defn.to_graphql
          field_defn.arguments[arg_graphql.name] = arg_graphql
        end

        field_defn
      end

      private

      class << self
        def argument_class(new_arg_class = nil)
          if new_arg_class
            @argument_class = new_arg_class
          else
            @argument_class || GraphQL::Schema::Argument
          end
        end
      end
    end
  end
end
