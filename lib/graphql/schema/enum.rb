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
      extend GraphQL::Schema::Member::AcceptsDefinition

      class << self
        extend Forwardable
        def_delegators :graphql_definition, :coerce_isolated_input, :coerce_isolated_result, :coerce_input, :coerce_result

        # Define a value for this enum
        # @param graphql_name [String, Symbol] the GraphQL value for this, usually `SCREAMING_CASE`
        # @param description [String], the GraphQL description for this value, present in documentation
        # @param value [Object], the translated Ruby value for this object (defaults to `graphql_name`)
        # @param deprecation_reason [String] if this object is deprecated, include a message here
        # @return [void]
        # @see {Schema::EnumValue} which handles these inputs by default
        def value(*args, **kwargs, &block)
          kwargs[:owner] = self
          value = enum_value_class.new(*args, **kwargs, &block)
          own_values[value.graphql_name] = value
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
            enum_type.add_value(val.to_graphql)
          end
          enum_type.metadata[:type_class] = self
          enum_type
        end

        # @return [Class] for handling `value(...)` inputs and building `GraphQL::Enum::EnumValue`s out of them
        def enum_value_class(new_enum_value_class = nil)
          if new_enum_value_class
            @enum_value_class = new_enum_value_class
          end
          @enum_value_class || (superclass <= GraphQL::Schema::Enum ? superclass.enum_value_class : nil)
        end

        def kind
          GraphQL::TypeKinds::ENUM
        end

        private

        def own_values
          @own_values ||= {}
        end
      end

      enum_value_class(GraphQL::Schema::EnumValue)
    end
  end
end
