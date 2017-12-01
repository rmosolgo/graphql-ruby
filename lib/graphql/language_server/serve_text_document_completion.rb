# frozen_string_literal: true
require "strscan"

module GraphQL
  class LanguageServer
    # The client requests code completion.
    # Call out to the provider and send the response to the client.
    class ServeTextDocumentCompletion < Response
      def response
        uri = request[:params][:textDocument][:uri]
        # Add one to match GraphQL-Ruby's parser
        cursor_line = request[:params][:position][:line] + 1
        cursor_col = request[:params][:position][:character]

        logger.debug("lookup: #{cursor_line}:#{cursor_col} of #{uri}")
        content = server.cache_content(uri)

        if !content
          logger.debug("No content for URI")
          return []
        end

        suggestion = CompletionSuggestion.new(
          text: content,
          line: cursor_line,
          column: cursor_col,
          server: server,
        )
        items = suggestion.items
        # Convert to LSP objects
        items.map do |item|
          LSP::Interface::CompletionItem.new(
            label: item.label,
            detail: item.detail,
            insert_text: item.insert_text,
            documentation: item.documentation,
            kind: item.kind,
          )
        end
      end
    end
  end
end
