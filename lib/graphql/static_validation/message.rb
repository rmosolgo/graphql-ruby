module GraphQL
  module StaticValidation
    # Generates GraphQL-compliant validation message.
    # Only supports one "location", too bad :(
    class Message
      # Convenience for validators
      module MessageHelper
        # Error `message` is located at `node`
        def message(message, node)
          GraphQL::StaticValidation::Message.new(message, line: node.line, col: node.col)
        end
      end
      attr_reader :message, :line, :col

      def initialize(message, line: nil, col: nil)
        @message = message
        @line = line
        @col = col
      end

      # A hash representation of this Message
      def to_h
        {
          "message" => message,
          "locations" => locations
        }
      end

      private

      def locations
        @line.nil? && @col.nil? ? [] : [{"line" => @line, "column" => @col}]
      end
    end
  end
end
