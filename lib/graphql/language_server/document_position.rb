# frozen_string_literal: true
module GraphQL
  class LanguageServer
    # Represents a location in a given text file
    class DocumentPosition
      attr_reader :filename, :text, :column, :line, :server
      def initialize(filename:, text:, line:, column:, server:)
        @text = text
        @line = line
        @filename = filename
        @column = column
        @server = server
      end

      def cursor
        @cursor ||= Cursor.fetch(document_position: self)
      end
    end
  end
end
