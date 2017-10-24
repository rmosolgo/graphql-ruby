# frozen_string_literal: true
module GraphQL
  class Object < GraphQL::SchemaMember
    class Argument
      NO_DEFAULT = :__no_default__

      attr_reader :name

      def initialize(arg_name, type_expr, desc = nil, null:, default_value: NO_DEFAULT)
        @name = arg_name.to_s
        @type_expr = type_expr
        @description = desc
        @null = null
        @default_value = default_value
      end

      def to_graphql
        argument = GraphQL::Argument.new
        argument.name = @name
        argument.type = -> {
          Object::BuildType.parse_type(@type_expr, null: @null)
        }
        argument.description = @description
        if @default_value != NO_DEFAULT
          argument.default_value = @default_value
        end
        argument
      end
    end
  end
end
