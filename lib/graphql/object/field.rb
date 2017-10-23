# frozen_string_literal: true
# test_via: ../object.rb

module GraphQL
  class Object < GraphQL::SchemaMember
    class Field
      attr_reader :name

      def initialize(name, return_type_expr, desc = nil, null:, deprecation_reason: nil, method: nil, &args_block)
        @name = name.to_s
        @description = desc
        @deprecation_reason = deprecation_reason
        @method = method
        @return_type_expr = return_type_expr
        @return_type_null = null
        @args_block = args_block
      end

      # @return [GraphQL::Field]
      def to_graphql
        return_type_name = BuildType.to_type_name(@return_type_expr)
        connection = return_type_name.end_with?("Connection")
        method_name = @method || BuildType.underscore(@name)

        field_defn = GraphQL::Field.new
        field_defn.name = @name
        field_defn.type = -> {
          Object::BuildType.parse_type(@return_type_expr, null: @return_type_null)
        }
        field_defn.description = @description
        field_defn.deprecation_reason = @deprecation_reason
        field_defn.resolve = GraphQL::Object::Resolvers::Dynamic.new({
          method_name: method_name,
        })
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

        def argument(arg_name, type_expr, desc = nil, null:, default_value: :__no_default__)
          arg_name = arg_name.to_s
          default_value_was_provided = default_value != :__no_default__
          # Rename to avoid naming conflict below
          provided_default_value = default_value

          argument = GraphQL::Argument.new
          argument.name = arg_name
          argument.type = -> {
            Object::BuildType.parse_type(type_expr, null: null)
          }
          argument.description = desc
          if default_value_was_provided
            argument.default_value = provided_default_value
          end

          @field.arguments[arg_name] = argument
        end
      end

    end
  end
end
