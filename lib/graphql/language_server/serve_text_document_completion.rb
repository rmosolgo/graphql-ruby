# frozen_string_literal: true
module GraphQL
  class LanguageServer
    # The client requests code completion.
    # Call out to the provider and send the response to the client.
    class ServeTextDocumentCompletion < Response
      def response
        document_position = DocumentPosition.from_params(request[:params], server: server)
        if document_position.nil?
          return []
        end

        suggestion = CompletionSuggestion.new(document_position: document_position)
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
