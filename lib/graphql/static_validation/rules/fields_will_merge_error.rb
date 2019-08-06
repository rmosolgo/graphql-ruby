# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class FieldsWillMergeError < StaticValidation::Error
      attr_reader :field_name
      attr_reader :conflicts

      def initialize(message, path: nil, nodes: [], field_name:, conflicts:)
        super(message, path: path, nodes: nodes)
        @field_name = field_name
        @conflicts = conflicts
      end

      # A hash representation of this Message
      def to_h
        extensions = {
          "code" => code,
          "fieldName" => field_name,
          "conflicts" => conflicts
        }

        super.merge({
          "extensions" => extensions
        })
      end

      def code
        "fieldConflict"
      end
    end
  end
end
