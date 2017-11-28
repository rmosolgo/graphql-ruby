# frozen_string_literal: true
module GraphQL
  class LanguageServer
    # Respond with the server's capabilities.
    #
    # These correspond with the various functionalities of `LanguageServer`.
    class ServeInitialize < Response
      def response
        LSP::Interface::InitializeResult.new(
          capabilities: LSP::Interface::ServerCapabilities.new(
            text_document_sync: LSP::Interface::TextDocumentSyncOptions.new(
              change: LSP::Constant::TextDocumentSyncKind::FULL
            ),
            # definition_provider: true,
            completion_provider: LSP::Interface::CompletionOptions.new(
              resolve_provider: true,
              trigger_characters: ["(",")"," "],
            ),
          )
        )
      end
    end
  end
end
