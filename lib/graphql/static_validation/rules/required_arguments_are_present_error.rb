# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  module StaticValidation
    class RequiredArgumentsArePresentError < StaticValidation::Error
      #: String
      attr_reader :class_name
      #: String
      attr_reader :name
      #: String
      attr_reader :arguments

      #: (String message, class_name: String, name: String, arguments: String, ?path: Array[String | Integer]?, ?nodes: GraphQL::Language::Nodes::AbstractNode | Array[GraphQL::Language::Nodes::AbstractNode]) -> void
      def initialize(message, class_name:, name:, arguments:, path: nil, nodes: [])
        super(message, path: path, nodes: nodes)
        @class_name = class_name #: String
        @name = name #: String
        @arguments = arguments #: String
      end

      # A hash representation of this Message
      #: -> Hash[String, untyped]
      def to_h
        extensions = {
          "code" => code,
          "className" => class_name,
          "name" => name,
          "arguments" => arguments
        }

        super.merge({
          "extensions" => extensions
        })
      end

      #: -> String
      def code
        "missingRequiredArguments"
      end
    end
  end
end
