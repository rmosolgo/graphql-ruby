# frozen_string_literal: true

module GraphQL
  class Enum < GraphQL::SchemaMember
    class << self
      def value(graphql_name, description = nil, value: nil, deprecation_reason: nil)
        graphql_name = graphql_name.to_s
        values << [graphql_name, description, value || graphql_name, deprecation_reason]
      end

      # TODO: inheritance?
      def values
        @values ||= []
      end

      def to_graphql
        enum_type = GraphQL::EnumType.new
        enum_type.name = graphql_name
        enum_type.description = description
        values.each do |(val_name, val_des, val_value, val_depr_reason)|
          enum_value = GraphQL::EnumType::EnumValue.new
          enum_value.name = val_name
          enum_value.description = val_des
          enum_value.value = val_value
          enum_value.deprecation_reason = val_depr_reason
          enum_type.add_value(enum_value)
        end
        enum_type
      end
    end
  end
end
