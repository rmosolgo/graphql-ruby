# frozen_string_literal: true

require 'graphql/schema/base_64_bp'

module GraphQL
  class Schema
    # @api private
    module Base64Encoder
      def self.encode(unencoded_text, nonce: false)
        Base64Bp.urlsafe_encode64(unencoded_text, padding: false)
      end

      def self.decode(encoded_text, nonce: false)
        # urlsafe_decode64 is for forward compatibility
        Base64Bp.urlsafe_decode64(encoded_text)
      rescue ArgumentError
        raise GraphQL::ExecutionError, "Invalid input: #{encoded_text.inspect}"
      end
    end
  end
end
