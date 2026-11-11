# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  module StaticValidation
    class VariableDefaultValuesAreCorrectlyTypedError < StaticValidation::Error
      #: String
      attr_reader :variable_name
      #: String?
      attr_reader :type_name
      #: String
      attr_reader :violation

      VIOLATIONS = {
        :INVALID_TYPE         => "defaultValueInvalidType",
        :INVALID_ON_NON_NULL  => "defaultValueInvalidOnNonNullVariable",
      } #: { INVALID_TYPE: String, INVALID_ON_NON_NULL: String }

      #: (String message, name: String, error_type: String, ?path: Array[String | Integer]?, ?nodes: GraphQL::Language::Nodes::AbstractNode | Array[GraphQL::Language::Nodes::AbstractNode], ?type: String?) -> void
      def initialize(message, name:, error_type:, path: nil, nodes: [], type: nil)
        super(message, path: path, nodes: nodes)
        @variable_name = name #: String
        @type_name = type #: String?
        raise("Unexpected error type: #{error_type}") if !VIOLATIONS.values.include?(error_type)
        @violation = error_type #: String
      end

      # A hash representation of this Message
      #: -> Hash[String, untyped]
      def to_h
        extensions = {
          "code" => code,
          "variableName" => variable_name
        }.tap { |h| h["typeName"] = type_name unless type_name.nil? }

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
