# frozen_string_literal: true

require 'graphql/schema/base_64_bp'

module GraphQL
  class Schema
    # @api private
    module Base64Encoder
      def self.encode(plaintext, nonce: false)
        Base64Bp.urlsafe_encode64(plaintext, padding: false)
      end

      def self.decode(ciphertext, nonce: false)
        # urlsafe_decode64 is for forward compatibility
        Base64Bp.urlsafe_decode64(ciphertext)
      end
    end
  end
end
