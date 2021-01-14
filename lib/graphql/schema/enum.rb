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
      extend GraphQL::Schema::Member::ValidatesInput

      class UnresolvedValueError < GraphQL::EnumType::UnresolvedValueError
      end

      class << self
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
          if own_values.key?(value.graphql_name)
            raise ArgumentError, "#{value.graphql_name} is already defined for #{self.graphql_name}, please remove one of the definitions."
          end
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
          enum_type.ast_node = ast_node
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
          elsif defined?(@enum_value_class) && @enum_value_class
            @enum_value_class
          else
            superclass <= GraphQL::Schema::Enum ? superclass.enum_value_class : nil
          end
        end

        def kind
          GraphQL::TypeKinds::ENUM
        end

        def validate_non_null_input(value_name, ctx)
          result = GraphQL::Query::InputValidationResult.new

          allowed_values = ctx.warden.enum_values(self)
          matching_value = allowed_values.find { |v| v.graphql_name == value_name }

          if matching_value.nil?
            result.add_problem("Expected #{GraphQL::Language.serialize(value_name)} to be one of: #{allowed_values.map(&:graphql_name).join(', ')}")
          end

          result
        end

        def coerce_result(value, ctx)
          warden = ctx.warden
          all_values = warden ? warden.enum_values(self) : values.each_value
          enum_value = all_values.find { |val| val.value == value }
          if enum_value
            enum_value.graphql_name
          else
            raise(self::UnresolvedValueError, "Can't resolve enum #{graphql_name} for #{value.inspect}")
          end
        end

        def coerce_input(value_name, ctx)
          all_values = ctx.warden ? ctx.warden.enum_values(self) : values.each_value

          if v = all_values.find { |val| val.graphql_name == value_name }
            v.value
          elsif v = all_values.find { |val| val.value == value_name }
            # this is for matching default values, which are "inputs", but they're
            # the Ruby value, not the GraphQL string.
            v.value
          else
            nil
          end
        end

        def inherited(child_class)
          child_class.const_set(:UnresolvedValueError, Class.new(Schema::Enum::UnresolvedValueError))
          super
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
