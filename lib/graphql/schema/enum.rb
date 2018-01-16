# frozen_string_literal: true

module GraphQL
  # Extend this class to define GraphQL enums in your schema.
  #
  # By default, GraphQL enum values are translated into Ruby strings.
  # You can provide a custom value with the `value:` keyword.
  #
  # @example
  #   # equivalent to
  #   # enum PizzaTopping {
  #   #   MUSHROOMS
  #   #   ONIONS
  #   #   PEPPERS
  #   # }
  #   class PizzaTopping < GraphQL::Enum
  #     value :MUSHROOMS
  #     value :ONIONS
  #     value :PEPPERS
  #   end
  class Schema
    class Enum < GraphQL::Schema::Member
      # @api private
      Value = Struct.new(:name, :description, :value, :deprecation_reason)

      class << self
        # Define a value for this enum
        # @param graphql_name [String, Symbol] the GraphQL value for this, usually `SCREAMING_CASE`
        # @param description [String], the GraphQL description for this value, present in documentation
        # @param value [Object], the translated Ruby value for this object (defaults to `graphql_name`)
        # @param deprecation_reason [String] if this object is deprecated, include a message here
        # @return [void]
        def value(graphql_name, description = nil, value: nil, deprecation_reason: nil)
          graphql_name = graphql_name.to_s
          value ||= graphql_name
          own_values[graphql_name] = Value.new(graphql_name, description, value, deprecation_reason)
          nil
        end

        # @return [Hash<String => GraphQL::Schema::Enum::Value>] Possible values of this enum, keyed by name
        def values
          inherited_values = superclass <= GraphQL::Schema::Enum ? superclass.values : {}
          # Local values take precedence over inherited ones
          inherited_values.merge(own_values)
        end

        # @return [GraphQL::EnumType]
        def to_graphql
          enum_type = GraphQL::EnumType.new
          enum_type.name = graphql_name
          enum_type.description = description
          enum_type.introspection = introspection
          values.each do |name, val|
            enum_value = GraphQL::EnumType::EnumValue.new
            enum_value.name = val.name
            enum_value.description = val.description
            enum_value.value = val.value
            enum_value.deprecation_reason = val.deprecation_reason
            enum_type.add_value(enum_value)
          end
          enum_type
        end

        private

        def own_values
          @own_values ||= {}
        end
      end
    end
  end
end
