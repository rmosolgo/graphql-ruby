# frozen_string_literal: true
module GraphQL
  class Schema
    # @api private
    module Base64Encoder
      def self.encode(plaintext, nonce: false)
        Base64.strict_encode64(plaintext)
      end

      def self.decode(ciphertext, nonce: false)
        Base64.decode64(ciphertext)
      end
    end
  end
end
