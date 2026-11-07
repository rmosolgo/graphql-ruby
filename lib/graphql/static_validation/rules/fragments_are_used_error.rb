# frozen_string_literal: true
# typed: strict
module GraphQL
  module StaticValidation
    class FragmentsAreUsedError < StaticValidation::Error
      #: String
      attr_reader :fragment_name

      #: (String message, fragment: String, ?path: Array[String | Integer]?, ?nodes: GraphQL::Language::Nodes::AbstractNode | Array[GraphQL::Language::Nodes::AbstractNode]) -> void
      def initialize(message, fragment:, path: nil, nodes: [])
        super(message, path: path, nodes: nodes)
        @fragment_name = fragment #: String
      end

      # A hash representation of this Message
      #: -> Hash[String, untyped]
      def to_h
        extensions = {
          "code" => code,
          "fragmentName" => fragment_name
        }

        super.merge({
          "extensions" => extensions
        })
      end

      #: -> String
      def code
        "useAndDefineFragment"
      end
    end
  end
end
