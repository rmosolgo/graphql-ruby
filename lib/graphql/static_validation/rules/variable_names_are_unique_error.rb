# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  module StaticValidation
    class VariableNamesAreUniqueError < StaticValidation::Error
      #: String
      attr_reader :variable_name

      #: (String message, name: String, ?path: Array[String | Integer]?, ?nodes: GraphQL::Language::Nodes::AbstractNode | Array[GraphQL::Language::Nodes::AbstractNode]) -> void
      def initialize(message, name:, path: nil, nodes: [])
        super(message, path: path, nodes: nodes)
        @variable_name = name #: String
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
        "variableNotUnique"
      end
    end
  end
end
