# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  module StaticValidation
    class FieldsHaveAppropriateSelectionsError < StaticValidation::Error
      #: String?
      attr_reader :type_name
      #: String
      attr_reader :node_name

      #: (String message, node_name: String, ?path: Array[String | Integer]?, ?nodes: GraphQL::Language::Nodes::AbstractNode | Array[GraphQL::Language::Nodes::AbstractNode], ?type: String?) -> void
      def initialize(message, node_name:, path: nil, nodes: [], type: nil)
        super(message, path: path, nodes: nodes)
        @node_name = node_name #: String
        @type_name = type #: String?
      end

      # A hash representation of this Message
      #: -> Hash[String, untyped]
      def to_h
        extensions = {
          "code" => code,
          "nodeName" => node_name
        }.tap { |h| h["typeName"] = type_name unless type_name.nil? }

        super.merge({
          "extensions" => extensions
        })
      end

      #: -> String
      def code
        "selectionMismatch"
      end
    end
  end
end
