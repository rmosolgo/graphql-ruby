# frozen_string_literal: true

module GraphQL
  class Schema
    # A possible value for an {Enum}.
    #
    # You can extend this class to customize enum values in your schema.
    #
    # @example custom enum value class
    #   # define a custom class:
    #   class CustomEnumValue < GraphQL::Schema::EnumValue
    #     def initialize(*args)
    #       # arguments to `value(...)` in Enum classes are passed here
    #       super
    #     end
    #
    #     def to_graphql
    #       enum_value = super
    #       # customize the derived GraphQL::EnumValue here
    #       enum_value
    #     end
    #   end
    #
    #   class BaseEnum < GraphQL::Schema::Enum
    #     # use it for these enums:
    #     enum_value_class CustomEnumValue
    #   end
    class EnumValue < GraphQL::Schema::Member
      include GraphQL::Schema::Member::AcceptsDefinition

      attr_reader :graphql_name

      # @return [Class] The enum type that owns this value
      attr_reader :owner

      def initialize(graphql_name, desc = nil, owner:, description: nil, value: nil, deprecation_reason: nil, &block)
        @graphql_name = graphql_name.to_s
        @description = desc || description
        @value = value || @graphql_name
        @deprecation_reason = deprecation_reason
        @owner = owner

        if block_given?
          instance_eval(&block)
        end
      end

      def description(new_desc = nil)
        if new_desc
          @description = new_desc
        end
        @description
      end

      def value(new_val = nil)
        if new_val
          @value = new_val
        end
        @value
      end

      # @return [GraphQL::EnumType::EnumValue] A runtime-ready object derived from this object
      def to_graphql
        enum_value = GraphQL::EnumType::EnumValue.new
        enum_value.name = @graphql_name
        enum_value.description = @description
        enum_value.value = @value
        enum_value.deprecation_reason = @deprecation_reason
        enum_value.metadata[:type_class] = self
        enum_value
      end
    end
  end
end
