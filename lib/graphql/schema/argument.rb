# frozen_string_literal: true
module GraphQL
  class Schema
    class Argument
      include GraphQL::Schema::Member::CachedGraphQLDefinition
      include GraphQL::Schema::Member::AcceptsDefinition

      NO_DEFAULT = :__no_default__

      attr_reader :name

      # @return [GraphQL::Schema::Field, Class] The field or input object this argument belongs to
      attr_reader :owner

      # @param arg_name [Symbol]
      # @param type_expr
      # @param desc [String]
      # @param required [Boolean] if true, this argument is non-null; if false, this argument is nullable
      # @param description [String]
      # @param default_value [Object]
      # @param camelize [Boolean] if true, the name will be camelized when building the schema
      def initialize(arg_name, type_expr, desc = nil, required:, description: nil, default_value: NO_DEFAULT, camelize: true, owner:, &definition_block)
        @name = arg_name.to_s
        @type_expr = type_expr
        @description = desc || description
        @null = !required
        @default_value = default_value
        @camelize = camelize
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

      def to_graphql
        argument = GraphQL::Argument.new
        argument.name = @camelize ? Member::BuildType.camelize(@name) : @name
        argument.type = -> { type }
        argument.description = @description
        argument.metadata[:type_class] = self
        if NO_DEFAULT != @default_value
          argument.default_value = @default_value
        end
        argument
      end

      def type
        @type ||= Member::BuildType.parse_type(@type_expr, null: @null)
      rescue StandardError => err
        raise "Couldn't build type for Argument #{@owner.name}.#{name}: #{err.class.name}: #{err.message}", err.backtrace
      end
    end
  end
end
