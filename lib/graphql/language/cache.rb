# frozen_string_literal: true

require 'graphql/version'
require 'digest/sha2'
require 'openssl'
require 'securerandom'
require 'tempfile'

module GraphQL
  module Language
    # This cache is used by {GraphQL::Language::Parser.parse_file} when it's enabled.
    #
    # With Rails, parser caching may enabled by setting `config.graphql.parser_cache = true` in your Rails application.
    #
    # The cache may be manually built by assigning `GraphQL::Language::Parser.cache = GraphQL::Language::Cache.new(Pathname.new("some_dir"), secret: ENV.fetch("GRAPHQL_CACHE_SECRET"))`.
    # The `secret` should be a stable value stored outside of the cache directory.
    # When it isn't provided, a process-local secret is generated and cache entries
    # are rebuilt after the process restarts.
    # This will create a directory (`tmp/cache/graphql` by default) that stores a cache of parsed files.
    #
    # Much like [bootsnap](https://github.com/Shopify/bootsnap), the parser cache needs to be cleaned up manually.
    # You will need to clear the cache directory for each new deployment of your application.
    # Also note that the parser cache will grow as your schema is loaded, so the cache directory must be writable.
    #
    # @see GraphQL::Railtie for simple Rails integration
    class Cache
      # @param path [Pathname] The directory where cache entries are stored.
      # @param secret [String, nil] A stable secret for verifying cache entries. When omitted,
      #   a process-local secret is generated.
      def initialize(path, secret: nil)
        @path = path
        @secret = secret || SecureRandom.random_bytes(32)
      end

      DIGEST = Digest::SHA256.new << GraphQL::VERSION
      HMAC_SIZE = OpenSSL::Digest::SHA256.new.digest_length
      InvalidCache = Class.new(StandardError)
      private_constant :InvalidCache

      def fetch(filename)
        cache_key = cache_key_for(filename)
        return yield unless cache_key

        cache_path = @path.join(cache_key)

        begin
          return load_cache(cache_path, cache_key) if cache_path.file?
        rescue InvalidCache, SystemCallError
          # Rebuild caches created by older versions or with an invalid signature.
        end

        payload = yield
        begin
          write_cache(cache_path, cache_key, payload)
        rescue SystemCallError
          # Parser caching is best-effort; return the parsed payload if the cache cannot be written.
        end
        payload
      end

      private

      def cache_key_for(filename)
        content_digest = Digest::SHA256.file(filename).hexdigest
        (DIGEST.dup << filename << content_digest).to_s
      rescue SystemCallError
        nil
      end

      def load_cache(cache_path, cache_key)
        cache_data = cache_path.binread
        signature = cache_data.byteslice(0, HMAC_SIZE)
        payload = cache_data.byteslice(HMAC_SIZE..-1)
        raise InvalidCache unless signature && payload

        expected_signature = signature_for(cache_key, payload)
        unless secure_compare(signature, expected_signature)
          raise InvalidCache
        end
        Marshal.load(payload)
      end

      def write_cache(cache_path, cache_key, payload)
        @path.mkpath
        serialized_payload = Marshal.dump(payload)
        cache_data = signature_for(cache_key, serialized_payload) + serialized_payload

        Tempfile.create(['graphql-cache-', '.tmp'], @path.to_s) do |tempfile|
          tempfile.binmode
          tempfile.write(cache_data)
          tempfile.flush
          tempfile.fsync
          tempfile.close
          File.rename(tempfile.path, cache_path.to_s)
        end
      end

      def signature_for(cache_key, payload)
        OpenSSL::HMAC.digest('SHA256', @secret, cache_key + payload)
      end

      def secure_compare(left, right)
        return false unless left.bytesize == right.bytesize

        result = 0
        left.bytes.each_with_index do |byte, index|
          result |= byte ^ right.getbyte(index)
        end
        result.zero?
      end
    end
  end
end
