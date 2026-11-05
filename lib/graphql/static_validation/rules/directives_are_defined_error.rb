# frozen_string_literal: true
# typed: strict
module GraphQL
  module StaticValidation
    class DirectivesAreDefinedError < StaticValidation::Error
      #: String
      attr_reader :directive_name

      #: (String message, directive: String, ?path: Array[String | Integer]?, ?nodes: GraphQL::Language::Nodes::AbstractNode | Array[GraphQL::Language::Nodes::AbstractNode]) -> void
      def initialize(message, directive:, path: nil, nodes: [])
        super(message, path: path, nodes: nodes)
        @directive_name = directive #: String
      end

      # A hash representation of this Message
      #: -> Hash[String, untyped]
      def to_h
        extensions = {
          "code" => code,
          "directiveName" => directive_name
        }

        super.merge({
          "extensions" => extensions
        })
      end

      #: -> String
      def code
        "undefinedDirective"
      end
    end
  end
end
