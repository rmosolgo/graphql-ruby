# frozen_string_literal: true

module GraphQL
  class Dataloader
    class Source
      # Include this module to make Source subclasses run their {#perform} methods inside `Concurrent::Promises.future { ... }`
      module BackgroundThreaded
        private

        # This is called when populating the promise cache.
        # In this case, also register the source for async processing.
        # (It might have already been registered by another `key`, the dataloader will ignore it in that case.)
        def make_lazy(key)
          lazy = super
          Dataloader.current.enqueue_async_source(self)
          lazy
        end

        # Like the superclass method, but:
        #
        # - Wrap the call to `super` inside a `Concurrent::Promises::Future`
        # - In the meantime, `fulfill(...)` each key with a lazy that will wait for the future
        #
        # Interestingly, that future will `fulfill(...)` each key with a finished value, so only the first
        # of the Lazies will actually be called. (Since the others will be replaced.)
        def perform_with_error_handling(keys_to_load)
          this_dl = Dataloader.current
          future = Concurrent::Promises.delay do
            Dataloader.load(this_dl) do
              super(keys_to_load)
            end
          end

          keys_to_load.each do |key|
            lazy = GraphQL::Execution::Lazy.new do
              future.value # force waiting for it to be finished
              fulfilled_value_for(key)
            end
            fulfill(key, lazy)
          end
          # Actually kick off the future:
          future.touch
          nil
        end
      end

      # @return [GraphQL::Execution::Lazy]
      def self.load(*key, value)
        self.for(*key).load(value)
      end

      # @return [Source] A cached instance of this class for the given {key_parts}
      def self.for(*key_parts)
        dl = Dataloader.current
        if !dl
          raise "Can't initialize a Source without a Dataloader, use `Dataloader.load { ... }` or add `use GraphQL::Dataloader` to your schema"
        end
        dl.source_for(self, key_parts)
      end

      # @return [GraphQL::Execution::Lazy]
      def self.load_all(*key_parts, values)
        pending_loads = values.map { |value| load(*key_parts, value) }
        Execution::Lazy.all(pending_loads)
      end

      # @see .load for a cache-friendly way to load objects during a query
      def load(key)
        pending_loads.compute_if_absent(key) { make_lazy(key) }
      end

      # Called by {Execution::Lazy}s that are waiting for this loader
      # @api private
      def wait
        # loads might be added in the meantime, but they won't be included in this list.
        keys_to_load = @load_queue
        @load_queue = nil
        perform_with_error_handling(keys_to_load)
      end

      # Mark {key} as having loaded {value}
      # @return void
      def fulfill(key, value)
        pending_loads[key].fulfill(value)
        nil
      end

      # @return [Boolean] true if `key` was loaded
      def fulfilled?(key)
        (lazy = pending_loads[key]) && lazy.resolved?
      end

      # This method should take `keys` and load a value for each one, then call `fulfill(k, value || nil)` to mark the load as successful
      # @param keys [Array<Object>] Whatever values have been passed to {#load} since this source's last perform call
      # @return void
      def perform(keys)
        raise RequiredImplementationMissingError, "`#{self.class}#perform(keys)` should call `fulfill(key, loaded_value)` for each of `keys`"
      end

      private

      def fulfilled_value_for(key)
        # TODO raise if not loaded?
        (lazy = pending_loads[key]) && lazy.value
      end

      def pending_loads
        @pending_loads ||= Concurrent::Map.new
      end

      def perform_with_error_handling(keys_to_load)
        perform(keys_to_load)
        nil
      rescue GraphQL::ExecutionError
        # Allow client-facing errors to keep propagating
        raise
      rescue StandardError => cause
        message = "Error from #{self.class}#perform(#{keys_to_load.map(&:inspect).join(", ")})\n\n#{cause.class}:\n#{cause.message.inspect}"
        load_err = GraphQL::Dataloader::LoadError.new(message)
        load_err.set_backtrace(cause.backtrace)
        load_err.cause = cause

        keys_to_load.each do |key|
          fulfill(key, load_err)
        end
        raise load_err
      end

      def make_lazy(key)
        @load_queue ||= []
        @load_queue << key
        Execution::Lazy.new(self)
      end
    end
  end
end
