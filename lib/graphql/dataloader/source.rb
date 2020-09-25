# frozen_string_literal: true

module GraphQL
  class Dataloader
    class Source
      module BackgroundThreaded
        def make_lazy(key)
          lazy = super
          Dataloader.current.enqueue_async_source(self)
          lazy
        end

        def perform_with_error_handling(keys_to_load)
          this_dl = Dataloader.current
          future = Concurrent::Promises.future do
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
        end
      end

      def self.load(*key, value)
        self.for(*key).load(value)
      end

      def self.for(*key_parts)
        dl = Dataloader.current
        if !dl
          raise "Can't initialize a Source without a Dataloader, use `Dataloader.load { ... }` or add `use GraphQL::Dataloader` to your schema"
        end
        dl.source_for(self, key_parts)
      end

      def self.load_all(key, values)
        pending_loads = values.map { |value| load(key, value) }
        Execution::Lazy.all(pending_loads)
      end

      def load(key)
        pending_loads.compute_if_absent(key) { make_lazy(key) }
      end

      def wait
        # loads might be added in the meantime, but they won't be included in this list.
        keys_to_load = @load_queue
        @load_queue = nil
        perform_with_error_handling(keys_to_load)
      end

      def fulfill(key, value)
        pending_loads[key].fulfill(value)
        nil
      end

      def fulfilled?(key)
        (lazy = pending_loads[key]) && lazy.resolved?
      end

      def perform(values)
        raise NotImplementedError, "`#{self.class}#perform(values)` should call `fulfill(v, loaded_value)` for each of `values`"
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
        message = "Error from #{self.class}#perform(#{keys_to_load.map(&:inspect).join(", ")}), #{cause.class}: #{cause.message.inspect}"
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
