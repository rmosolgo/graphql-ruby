# frozen_string_literal: true

module GraphQL
  class Dataloader
    class Source
      def initialize(context)
        @context = context
        @pending_keys = []
        @results = {}
      end

      def load(key)
        if @results.key?(key)
          @results[key]
        else
          sync([key])
          @results[key]
        end
      end

      def load_all(keys)
        if keys.any? { |k| !@results.key?(k) }
          pending_keys = keys.select { |k| !@results.key?(k) }
          sync(pending_keys)
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
      def sync(this_fiber_pending_keys)
        @pending_keys.concat(this_fiber_pending_keys)
        interpreter_ctx = @context.namespace(:interpreter)
        progress_ctx = interpreter_ctx[:next_progress]
        if progress_ctx[:passed_along]
          # This fiber already passed the baton
          Fiber.yield
        else
          progress_ctx[:passed_along] = true
          progress = interpreter_ctx[:runtime].make_selections_fiber
          Fiber.yield(progress)
        end
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
