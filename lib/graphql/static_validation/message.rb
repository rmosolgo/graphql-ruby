# frozen_string_literal: true
module GraphQL
  module StaticValidation
    # Generates GraphQL-compliant validation message.
    class Message
      # Convenience for validators
      module MessageHelper
        # Error `message` is located at `node`
        def message(message, nodes, context: nil, path: nil)
          path ||= context.path
          nodes = Array(nodes)
          GraphQL::StaticValidation::Message.new(message, nodes: nodes, path: path)
        end
      end

      attr_reader :message, :path

      def initialize(message, path: [], nodes: [])
        @message = message
        @nodes = nodes
        @path = path
      end

      # A hash representation of this Message
      def to_h
        {
          "message" => message,
          "locations" => locations,
          "fields" => path,
        }
      end

      private

      def locations
        @nodes.map do |node|
          h = {"line" => node.line, "column" => node.col}
          h["filename"] = node.filename if node.filename
          h
        end
      end
    end
  end
end
