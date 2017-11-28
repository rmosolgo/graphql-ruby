# frozen_string_literal: true
module GraphQL
  class LanguageServer
    # Respond to this event by updating the in-memory cache of file contents.
    #
    # Someday, we could maintain an incremental cache,
    # that would require an update to ServeInitialize too,
    # so that the client knows to send us incremental updates.
    class ServeTextDocumentDidChange < Response
      def response
        uri = request[:params][:textDocument][:uri]
        # TODO are there sometimes multiple content changes?
        content = request[:params][:contentChanges][0][:text]
        server.cache_content(uri, content)
        nil
      end
    end
  end
end
