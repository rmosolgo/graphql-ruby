# frozen_string_literal: true
# typed: strict
module GraphQL
  module StaticValidation
    class FragmentsAreNamedError < StaticValidation::Error

      #: (String message, ?path: Array[String | Integer]?, ?nodes: GraphQL::Language::Nodes::AbstractNode | Array[GraphQL::Language::Nodes::AbstractNode]) -> void
      def initialize(message, path: nil, nodes: [])
        super(message, path: path, nodes: nodes)
      end

      # A hash representation of this Message
      #: -> Hash[String, untyped]
      def to_h
        extensions = {
          "code" => code,
        }

        super.merge({
          "extensions" => extensions
        })
      end

      #: -> String
      def code
        "anonymousFragment"
      end
    end
  end
end
