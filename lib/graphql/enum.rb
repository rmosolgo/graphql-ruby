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
        @to_graphql ||= begin
          enum_class = self
          GraphQL::EnumType.define do
            name(enum_class.graphql_name)
            description(enum_class.description)
            enum_class.values.each do |(val_name, val_desc, val_value, val_depr_reason)|
              value(val_name, val_desc, value: val_value, deprecation_reason: val_depr_reason)
            end
          end
        end
      end
    end
  end
end
