# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  module StaticValidation
    class VariablesAreUsedAndDefinedError < StaticValidation::Error
      #: String
      attr_reader :variable_name
      #: String
      attr_reader :violation

      VIOLATIONS = {
        :VARIABLE_NOT_USED     => "variableNotUsed",
        :VARIABLE_NOT_DEFINED  => "variableNotDefined",
      } #: { VARIABLE_NOT_USED: String, VARIABLE_NOT_DEFINED: String }

      #: (String message, name: String, error_type: String, ?path: Array[String | Integer]?, ?nodes: GraphQL::Language::Nodes::AbstractNode | Array[GraphQL::Language::Nodes::AbstractNode]) -> void
      def initialize(message, name:, error_type:, path: nil, nodes: [])
        super(message, path: path, nodes: nodes)
        @variable_name = name #: String
        raise("Unexpected error type: #{error_type}") if !VIOLATIONS.values.include?(error_type)
        @violation = error_type #: String
      end

      # A hash representation of this Message
      #: -> Hash[String, untyped]
      def to_h
        extensions = {
          "code" => code,
          "variableName" => variable_name
        }

        super.merge({
          "extensions" => extensions
        })
      end

      #: -> String
      def code
        @violation
      end
    end
  end
end
