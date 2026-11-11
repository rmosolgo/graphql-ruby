# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  module StaticValidation
    class VariableUsagesAreAllowedError < StaticValidation::Error
      #: String
      attr_reader :type_name
      #: String
      attr_reader :variable_name
      #: String
      attr_reader :argument_name
      #: String
      attr_reader :error_message

      #: (String message, type: String, name: String, argument: String, error: String, ?path: Array[String | Integer]?, ?nodes: GraphQL::Language::Nodes::AbstractNode | Array[GraphQL::Language::Nodes::AbstractNode]) -> void
      def initialize(message, type:, name:, argument:, error:, path: nil, nodes: [])
        super(message, path: path, nodes: nodes)
        @type_name = type #: String
        @variable_name = name #: String
        @argument_name = argument #: String
        @error_message = error #: String
      end

      # A hash representation of this Message
      #: -> Hash[String, untyped]
      def to_h
        extensions = {
          "code" => code,
          "variableName" => variable_name,
          "typeName" => type_name,
          "argumentName" => argument_name,
          "errorMessage" => error_message
        }

        super.merge({
          "extensions" => extensions
        })
      end

      #: -> String
      def code
        "variableMismatch"
      end
    end
  end
end
