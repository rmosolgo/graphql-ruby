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
      attr_reader :description

      def initialize(name, return_type_expr = nil, desc = nil, null: nil, field: nil, function: nil, deprecation_reason: nil, method: nil, connection: nil, max_page_size: nil, resolve: nil, introspection: false, extras: [], &args_block)
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
        @description = desc
        @field = field
        @function = function
        @resolve = resolve
        @deprecation_reason = deprecation_reason
        @method = method
        @return_type_expr = return_type_expr
        @return_type_null = null
        @args_block = args_block
        @connection = connection
        @max_page_size = max_page_size
        @introspection = introspection
        @extras = extras
      end

      # @return [GraphQL::Field]
      def to_graphql
        method_name = @method || Member::BuildType.underscore(@name)

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

        field_proxy = FieldProxy.new(field_defn, argument_class: self.class.argument_class)
        # apply this first, so it can be overriden below
        if connection
          field_proxy.argument :after, "String", "Returns the elements in the list that come after the specified global ID.", required: false
          field_proxy.argument :before, "String", "Returns the elements in the list that come before the specified global ID.", required: false
          field_proxy.argument :first, "Int", "Returns the first _n_ elements from the list.", required: false
          field_proxy.argument :last, "Int", "Returns the last _n_ elements from the list.", required: false
        end

        if @args_block
          field_proxy.instance_eval(&@args_block)
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


      # This object exists only to be `instance_eval`'d
      # when the `field(...)` method is called with a block.
      # This object receives that block.
      class FieldProxy
        def initialize(field, argument_class:)
          @field = field
          @argument_class = argument_class
        end

        # This is the `argument(...)` DSL for class-based field definitons
        def argument(*args)
          arg = @argument_class.new(*args)
          graphql_arg = arg.graphql_definition
          @field.arguments[graphql_arg.name] = graphql_arg
        end

        def description(text)
          if @field.description
            fail "You're overriding the description of #{@field.name} in the provided block!"
          else
            @field.description = text
          end
        end
      end
    end
  end
end
