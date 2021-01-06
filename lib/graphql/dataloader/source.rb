# frozen_string_literal: true

module GraphQL
  class Dataloader
    class Source
      # @api private
      attr_reader :results

      # Called by {Dataloader} to prepare the {Source}'s internal state
      # @api private
      def setup(dataloader)
        @pending_keys = []
        @results = {}
        @dataloader = dataloader
      end

      attr_reader :dataloader

      # @return [Dataloader::Request] a pending request for a value from `key`. Call `.load` on that object to wait for the result.
      def request(key)
        if !@results.key?(key)
          @pending_keys << key
        end
        Dataloader::Request.new(self, key)
      end

      # @return [Dataloader::Request] a pending request for a values from `keys`. Call `.load` on that object to wait for the results.
      def request_all(keys)
        pending_keys = keys.select { |k| !@results.key?(k) }
        @pending_keys.concat(pending_keys)
        Dataloader::RequestAll.new(self, keys)
      end

      # @param key [Object] A loading key which will be passed to {#fetch} if it isn't already in the internal cache.
      # @return [Object] The result from {#fetch} for `key`. If `key` hasn't been loaded yet, the Fiber will yield until it's loaded.
      def load(key)
        if @results.key?(key)
          @results[key]
        else
          @pending_keys << key
          sync
          @results[key]
        end
      end

      # @param keys [Array<Object>] Loading keys which will be passed to `#fetch` (or read from the internal cache).
      # @return [Object] The result from {#fetch} for `keys`. If `keys` haven't been loaded yet, the Fiber will yield until they're loaded.
      def load_all(keys)
        if keys.any? { |k| !@results.key?(k) }
          pending_keys = keys.select { |k| !@results.key?(k) }
          @pending_keys.concat(pending_keys)
          sync
        end

        keys.map { |k| @results[k] }
      end

      # Subclasses must implement this method to return a value for each of `keys`
      # @param keys [Array<Object>] keys passed to {#load}, {#load_all}, {#request}, or {#request_all}
      # @return [Array<Object>] A loaded value for each of `keys`. The array must match one-for-one to the list of `keys`.
      def fetch(keys)
        # somehow retrieve these from the backend
        raise "Implement `#{self.class}#fetch(#{keys.inspect}) to return a record for each of the keys"
      end

      # Wait for a batch, if there's anything to batch.
      # Then run the batch and update the cache.
      # @return [void]
      def sync
        @dataloader.yield
      end

      # @return [Boolean] True if this source has any pending requests for data.
      def pending?
        @pending_keys.any?
      end

      # Called by {GraphQL::Dataloader} to resolve and pending requests to this source.
      # @api private
      # @return [void]
      def run_pending_keys
        return if @pending_keys.empty?
        fetch_keys = @pending_keys.uniq
        @pending_keys = []
        results = fetch(fetch_keys)
        fetch_keys.each_with_index do |key, idx|
          @results[key] = results[idx]
        end
        nil
      end
    end
  end
end
