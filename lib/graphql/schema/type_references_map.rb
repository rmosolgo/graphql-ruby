# frozen_string_literal: true
module GraphQL
  class Schema
    module TypeReferencesMap
      # @param types [Array<GraphQL::Field>] fields of a schema
      # @return { GraphQL::BaseType => Array<Field|Argument> }
      def self.from_fields(fields)
        map = Hash.new { |h, k| h[k] = [] }
        fields.reduce(map) do |type_references, field|
          type_references[field.type.unwrap.to_s] << field

          field.arguments.each_value do |argument|
            type_references[argument.type.unwrap.to_s] << argument
          end

          type_references
        end
      end
    end
  end
end
