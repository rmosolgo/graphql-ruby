# frozen_string_literal: true

module GraphQL
  class Dataloader
    class Source
      class Request
        def initialize(source, key)
          @source = source
          @key = key
        end

        def load
          @source.sync
          @source.results[@key]
        end
      end

      attr_reader :results

      def initialize(context)
        @context = context
        @pending_keys = []
        @results = {}
        @dataloader = @context.query.multiplex.dataloader
      end

      def request(key)
        if !@results.key?(key)
          @pending_keys << key
        end
        Request.new(self, key)
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
        interpreter_ctx = @context.namespace(:interpreter)
        progress_ctx = interpreter_ctx[:next_progress]
        if !progress_ctx[:passed_along]
          progress_ctx[:passed_along] = true
          next_fiber = interpreter_ctx[:runtime].make_selections_fiber
          @dataloader.enqueue(next_fiber)
        end
        @dataloader.yield
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
