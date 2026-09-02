# frozen_string_literal: true

require 'digest/sha2'

module GraphQL
  class Query
    # The resulting hashes are exposed by `Query#operation_fingerprint`,
    # `Query#variables_fingerprint`, and `Query#fingerprint`.
    module Fingerprint # :nodoc:
      # Make an obfuscated hash of the given string (either a query string or variables JSON)
      #
      # **Parameters**
      #
      # - `string` (`String`)
      #
      # **Returns**
      #
      # - `String` — A normalized, opaque hash
      #
      # :call-seq:
      #   generate(input_str) -> String
      def self.generate(input_str)
        # Implemented to be:
        # - Short (and uniform) length
        # - Stable
        # - Irreversibly Opaque (don't want to leak variable values)
        # - URL-friendly
        bytes = Digest::SHA256.digest(input_str)
        Base64.urlsafe_encode64(bytes)
      end
    end
  end
end
