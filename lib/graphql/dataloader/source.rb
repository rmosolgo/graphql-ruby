# frozen_string_literal: true

module GraphQL
  class Dataloader
    class Source
      attr_reader :results

      def initialize(dataloader)
        @pending_keys = []
        @results = {}
        @dataloader = dataloader
      end

      def request(key)
        if !@results.key?(key)
          @pending_keys << key
        end
        Dataloader::Request.new(self, key)
      end

      def request_all(keys)
        pending_keys = keys.select { |k| !@results.key?(k) }
        @pending_keys.concat(pending_keys)
        Dataloader::RequestAll.new(self, keys)
      end

      def load(key)
        if @results.key?(key)
          @results[key]
        else
          @pending_keys << key
          sync
          @results[key]
        end
      end

      def load_all(keys)
        if keys.any? { |k| !@results.key?(k) }
          pending_keys = keys.select { |k| !@results.key?(k) }
          @pending_keys.concat(pending_keys)
          sync
        end

        keys.map { |k| @results[k] }
      end

      def fetch(keys)
        # somehow retrieve these from the backend
        raise "Implement `#{self.class}#fetch(#{keys.inspect}) to return a record for each of the keys"
      end

      # Wait for a batch, if there's anything to batch.
      # Then run the batch and update the cache.
      # @return [void]
      def sync
        progress_ctx = @dataloader.context[:next_progress]
        if !progress_ctx[:passed_along]
          progress_ctx[:passed_along] = true
          next_fiber = progress_ctx[:runtime].make_selections_fiber
          @dataloader.enqueue(next_fiber)
        end
        @dataloader.yield
      end

      def pending?
        @pending_keys.any?
      end

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
