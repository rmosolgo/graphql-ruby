# frozen_string_literal: true

require 'digest/sha2'

module GraphQL
  class Query
    # **API:** private
    # See [Query#query_fingerprint](rdoc-ref:Query#query_fingerprint) Query#query_fingerprint
    # See [Query#variables_fingerprint](rdoc-ref:Query#variables_fingerprint) Query#variables_fingerprint
    # See [Query#fingerprint](rdoc-ref:Query#fingerprint) Query#fingerprint
    module Fingerprint
      # Make an obfuscated hash of the given string (either a query string or variables JSON)
      #
      # **Parameters**
      #
      # - `string` (`String`)
      #
      # **Returns**
      #
      # - `String` — A normalized, opaque hash
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
