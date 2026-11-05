# frozen_string_literal: true
# typed: true
module GraphQL
  module StaticValidation
    class VariablesAreInputTypesError < StaticValidation::Error
      attr_reader :type_name
      attr_reader :variable_name

      def initialize(message, type:, name:, path: nil, nodes: [])
        super(message, path: path, nodes: nodes)
        @type_name = type
        @variable_name = name
      end

      # A hash representation of this Message
      def to_h
        extensions = {
          "code" => code,
          "typeName" => type_name,
          "variableName" => variable_name
        }

        super.merge({
          "extensions" => extensions
        })
      end

      def code
        "variableRequiresValidType"
      end
    end
  end
end
