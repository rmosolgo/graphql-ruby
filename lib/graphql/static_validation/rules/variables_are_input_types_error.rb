# frozen_string_literal: true
# typed: strict
module GraphQL
  module StaticValidation
    class VariablesAreInputTypesError < StaticValidation::Error
      #: String
      attr_reader :type_name
      #: String
      attr_reader :variable_name

      #: (String message, type: String, name: String, ?path: Array[String | Integer]?, ?nodes: GraphQL::Language::Nodes::AbstractNode | Array[GraphQL::Language::Nodes::AbstractNode]) -> void
      def initialize(message, type:, name:, path: nil, nodes: [])
        super(message, path: path, nodes: nodes)
        @type_name = type #: String
        @variable_name = name #: String
      end

      # A hash representation of this Message
      #: -> Hash[String, untyped]
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

      #: -> String
      def code
        "variableRequiresValidType"
      end
    end
  end
end
