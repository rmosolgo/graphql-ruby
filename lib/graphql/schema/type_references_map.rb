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

          derive_from_arguments(type_references, field)

          type_references
        end
      end

      private

      def self.derive_from_arguments(type_references, argument_owner, seen = {})
        return unless argument_owner.arguments.any?

        return if seen[argument_owner.name]
        seen[argument_owner.name] = true

        argument_owner.arguments.each_value do |argument|
          type_references[argument.type.unwrap.to_s] << argument

          if argument.type.kind.input_object?
            derive_from_arguments(type_references, argument.type, seen)
          end
        end
      end
    end
  end
end
