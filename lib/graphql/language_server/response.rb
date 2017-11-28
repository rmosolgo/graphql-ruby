# frozen_string_literal: true
module GraphQL
  class LanguageServer
    # Base class for various language server responses.
    # They're initialized by `LanguageServer` and
    # their `#response` methods are called.
    class Response
      attr_reader :request, :server, :logger
      def initialize(request:, server:, logger:)
        @server = server
        @request = request
        @logger = logger
      end

      def response
        raise NotImplementedError, "#{self.class.name}#response should return a JSON-ready protocol object or nil"
      end
    end
  end
end
