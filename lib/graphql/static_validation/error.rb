# frozen_string_literal: true
# typed: strict
module GraphQL
  module StaticValidation
    # Generates GraphQL-compliant validation message.
    class Error
      # Convenience for validators
      #--
      # @requires_ancestor: Kernel
      module ErrorHelper
        # Error `error_message` is located at `node`
        #: (String error_message, GraphQL::Language::Nodes::AbstractNode | Array[GraphQL::Language::Nodes::AbstractNode] nodes, ?context: GraphQL::StaticValidation::ValidationContext?, ?path: Array[String | Integer]?, ?extensions: Hash[String, untyped]) -> GraphQL::StaticValidation::Error
        def error(error_message, nodes, context: nil, path: nil, extensions: {})
          path ||= (context #: as !nil
            ).path
          nodes = Array(nodes)
          GraphQL::StaticValidation::Error.new(error_message, nodes: nodes, path: path)
        end
      end

      #: String?
      attr_reader   :message
      #: Array[String | Integer]?
      attr_accessor :path

      #: (String? message, ?path: Array[String | Integer]?, ?nodes: GraphQL::Language::Nodes::AbstractNode | Array[GraphQL::Language::Nodes::AbstractNode]) -> void
      def initialize(message, path: nil, nodes: [])
        @message = message #: String?
        @nodes = Array(nodes) #: Array[GraphQL::Language::Nodes::AbstractNode]
        @path = path #: Array[String | Integer]?
      end

      # A hash representation of this Message
      #: -> Hash[String, untyped]
      def to_h
        {
          "message" => message,
          "locations" => locations
        }.tap { |h| h["path"] = path unless path.nil? }
      end

      #: Array[GraphQL::Language::Nodes::AbstractNode]
      attr_reader :nodes

      private

      #: -> Array[Hash[String, untyped]]
      def locations
        nodes.map do |node|
          h = {"line" => node.line, "column" => node.col}
          h["filename"] = node.filename if node.filename
          h
        end
      end
    end
  end
end
