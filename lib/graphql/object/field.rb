# frozen_string_literal: true
# test_via: ../object.rb

module GraphQL
  class Object < GraphQL::SchemaMember
    class Field
      include GraphQL::SchemaMember::CachedGraphQLDefinition

      # @return [String]
      attr_reader :name

      # @return [String]
      attr_reader :description

      def initialize(name, return_type_expr = nil, desc = nil, null: nil, field: nil, function: nil, deprecation_reason: nil, method: nil, connection: nil, max_page_size: nil, resolve: nil, &args_block)
        if !(field || function)
          if return_type_expr.nil?
            raise ArgumentError "missing possitional argument `type`"
          end
          if null.nil?
            raise ArgumentError, "missing keyword argument null:"
          end
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
      end

      # @return [GraphQL::Field]
      def to_graphql
        method_name = @method || BuildType.underscore(@name)

        field_defn = if @field
          @field.dup
        elsif @function
          GraphQL::Function.build_field(@function)
        else
          GraphQL::Field.new
        end
        field_defn.name = @name

        if @return_type_expr
          return_type_name = BuildType.to_type_name(@return_type_expr)
          connection = @connection.nil? ? return_type_name.end_with?("Connection") : @connection
          field_defn.type = -> {
            Object::BuildType.parse_type(@return_type_expr, null: @return_type_null)
          }
        elsif @connection.nil? && (@field || @function)
          return_type_name = BuildType.to_type_name(field_defn.type)
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
          GraphQL::Object::Resolvers::Dynamic.new({
            method_name: method_name,
            connection: connection,
          })
        end

        field_defn.connection = connection
        field_defn.connection_max_page_size = @max_page_size

        # apply this first, so it can be overriden below
        if connection
          conn_args = FieldProxy.new(field_defn)
          conn_args.argument :after, "String", "Returns the elements in the list that come after the specified global ID.", null: true
          conn_args.argument :before, "String", "Returns the elements in the list that come before the specified global ID.", null: true
          conn_args.argument :first, "Int", "Returns the first _n_ elements from the list.", null: true
          conn_args.argument :last, "Int", "Returns the last _n_ elements from the list.", null: true
        end

        if @args_block
          FieldProxy.new(field_defn).instance_eval(&@args_block)
        end

        field_defn
      end


      class FieldProxy
        def initialize(field)
          @field = field
        end

        def argument(*args)
          arg = GraphQL::Object::Argument.new(*args)
          @field.arguments[arg.name] = arg.graphql_definition
        end
      end

      class UnwrappedResolve
        def initialize(inner_resolve:)
          @inner_resolve = inner_resolve
        end

        def call(obj, args, ctx)
          # Might be nil, still want to call the func in that case
          inner_obj = obj && obj.object
          @inner_resolve.call(inner_obj, args, ctx)
        end
      end
    end
  end
end
