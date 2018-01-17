# frozen_string_literal: true
module GraphQL
  class Schema
    class Argument
      include GraphQL::Schema::Member::CachedGraphQLDefinition

      NO_DEFAULT = :__no_default__

      attr_reader :name

      def initialize(arg_name, type_expr, desc = nil, required:, default_value: NO_DEFAULT)
        @name = arg_name.to_s
        @type_expr = type_expr
        @description = desc
        @null = !required
        @default_value = default_value
      end

      def to_graphql
        argument = GraphQL::Argument.new
        argument.name = Member::BuildType.camelize(@name)
        argument.type = -> {
          Member::BuildType.parse_type(@type_expr, null: @null)
        }
        argument.description = @description
        if NO_DEFAULT != @default_value
          argument.default_value = @default_value
        end
        argument
      end
    end
  end
end
