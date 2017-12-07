# frozen_string_literal: true
module GraphQL
  class LanguageServer
    class SignatureHelp
      def initialize(document_position:)
        @document_position = document_position
        @server = document_position.server
      end

      def active_signature
        load_signature
        @active_signature
      end

      private

      def load_signature
        if defined?(@active_signature)
          return
        end
        cursor = @document_position.cursor
        @active_signature = cursor.current_input
      end
    end
  end
end
