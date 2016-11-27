module GraphQL
  class Schema
    # @api private
    module Base64Encoder
      def self.encode(plaintext)
        Base64.strict_encode64(plaintext)
      end

      def self.decode(ciphertext)
        Base64.decode64(ciphertext)
      end
    end
  end
end
