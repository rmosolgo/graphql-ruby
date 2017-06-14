# frozen_string_literal: true
module GraphQL
  class Schema
    # @api private
    module Base64Encoder
      @warned = false

      def self.warn_once(*args)
        return if @warned
        @warned = true
        warn('GraphQL::Schema::Base64Encoder has been renamed to GraphQL::Schema::Coders::Base64Coder')
      end

      def self.encode(plaintext, nonce: false)
        warn_once
        Coders::Base64Coder.encode(plaintext, nonce: nonce)
      end

      def self.decode(ciphertext, nonce: false)
        warn_once
        Coders::Base64Coder.decode(ciphertext, nonce: nonce)
      end
    end
  end
end
