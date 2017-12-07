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

      # TODO: this calculation should be cached _somehow_.
      # For example, `textDocument/completion` and `textDocument/signatureHelp`
      # come in quick succession and could use the same cursor data.
      # @return [Cursor]
      def cursor
        @cursor ||= Cursor.fetch(document_position: self)
      end

      # @return [DocumentPosition, nil]
      def self.from_params(params, server:)
        uri = params[:textDocument][:uri]
        # Add one to match GraphQL-Ruby's parser
        cursor_line = params[:position][:line] + 1
        cursor_col = params[:position][:character]

        server.logger.debug("lookup: #{cursor_line}:#{cursor_col} of #{uri}")
        content = server.cache_content(uri)

        if !content
          server.logger.debug("No content for URI")
          nil
        else
          DocumentPosition.new(
            text: content,
            line: cursor_line,
            column: cursor_col,
            server: server,
            filename: uri,
          )
        end
      end
    end
  end
end
