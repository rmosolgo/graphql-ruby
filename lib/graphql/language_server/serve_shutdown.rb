# frozen_string_literal: true
module GraphQL
  class LanguageServer
    # A minimal response so that the client knows we got the message
    class ServeShutdown < Response
      def response
        {}
      end
    end
  end
end
