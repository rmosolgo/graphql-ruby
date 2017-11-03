# frozen_string_literal: true

module GraphQL
  class Enum < GraphQL::SchemaMember
    Value = Struct.new(:name, :description, :value, :deprecation_reason)
    class << self
      def value(graphql_name, description = nil, value: nil, deprecation_reason: nil)
        graphql_name = graphql_name.to_s
        value ||= graphql_name
        own_values << Value.new(graphql_name, description, value, deprecation_reason)
      end

      def values
        all_values = own_values
        inherited_values = superclass <= GraphQL::Enum ? superclass.values : []
        inherited_values.each do |inherited_v|
          if all_values.none? { |v| v.name == inherited_v.name }
            all_values << inherited_v
          end
        end
        all_values
      end

      def own_values
        @own_values ||= []
      end

      def to_graphql
        enum_type = GraphQL::EnumType.new
        enum_type.name = graphql_name
        enum_type.description = description
        values.each do |val|
          enum_value = GraphQL::EnumType::EnumValue.new
          enum_value.name = val.name
          enum_value.description = val.description
          enum_value.value = val.value
          enum_value.deprecation_reason = val.deprecation_reason
          enum_type.add_value(enum_value)
        end
        enum_type
      end
    end
  end
end
