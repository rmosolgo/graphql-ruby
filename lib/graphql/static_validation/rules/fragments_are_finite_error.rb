# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  module StaticValidation
    class FragmentsAreFiniteError < StaticValidation::Error
      #: String
      attr_reader :fragment_name

      #: (String message, name: String, ?path: Array[String | Integer]?, ?nodes: GraphQL::Language::Nodes::AbstractNode | Array[GraphQL::Language::Nodes::AbstractNode]) -> void
      def initialize(message, name:, path: nil, nodes: [])
        super(message, path: path, nodes: nodes)
        @fragment_name = name #: String
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
        "infiniteLoop"
      end
    end
  end
end
