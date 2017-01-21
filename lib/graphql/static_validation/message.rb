# frozen_string_literal: true
module GraphQL
  module StaticValidation
    # Generates GraphQL-compliant validation message.
    class Message
      # Convenience for validators
      module MessageHelper
        # Error `message` is located at `node`
        def message(message, nodes)
          nodes = Array(nodes)
          GraphQL::StaticValidation::Message.new(message, nodes: nodes)
        end
      end

      attr_reader :message, :path

      def initialize(message, path: nil, nodes: [])
        @message = message
        @nodes = nodes
        first_node = nodes.first
        @path = path ? path : (first_node ? first_node.path : [])
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
        @nodes.map{|node| {"line" => node.line, "column" => node.col}}
      end
    end
  end
end
