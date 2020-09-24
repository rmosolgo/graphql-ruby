# frozen_string_literal: true

module GraphQL
  class Dataloader
    class Loader
      module BackgroundThreaded
        def wait
          # loads might be added in the meantime, but they won't be included in this list.
          keys_to_load = @load_queue
          @load_queue = nil
          this_dl = Dataloader.current
          f = Concurrent::Future.new do
              Dataloader.load(this_dl) do
                perform_with_error_handling(keys_to_load)
              end
            end
          end
          keys_to_load.each do |key|
            lazy = GraphQL::Execution::Lazy.new do
              f.value # force waiting for it to be finished
              fulfilled_value_for(key)
            end
            fulfill(key, lazy)
          end
          f.execute
          nil
        end
      end

      def self.load(*key, value)
        self.for(*key).load(value)
      end

      def self.for(*key_parts)
        dl = Dataloader.current
        if !dl
          raise "Can't initialize a loader without a Dataloader, use `Dataloader.load { ... }` or add `use GraphQL::Dataloader` to your schema"
        end
        dl.loaders[self][key_parts]
      end

      def self.load_all(key, values)
        pending_loads = values.map { |value| load(key, value) }
        Execution::Lazy.all(pending_loads)
      end

      def initialize(*key)
        @key = key
      end

      def load(key)
        pending_loads[key] ||= begin
          @load_queue ||= []
          @load_queue << key
          # return this lazy:
          Execution::Lazy.new(self)
        end
      end

      def wait
        # loads might be added in the meantime, but they won't be included in this list.
        keys_to_load = @load_queue
        @load_queue = nil
        perform_with_error_handling(keys_to_load)
      end

      def perform_with_error_handling(keys_to_load)
        begin
          perform(keys_to_load)
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
        nil
      end

      def fulfill(key, value)
        pending_loads[key].fulfill(value)
        nil
      end

      def fulfilled?(key)
        (lazy = pending_loads[key]) && lazy.resolved?
      end

      def fulfilled_value_for(key)
        # TODO raise if not loaded?
        (lazy = pending_loads[key]) && lazy.value
      end

      def perform(values)
        raise NotImplementedError, "`#{self.class}#perform(values)` should call `fulfill(v, loaded_value)` for each of `values`"
      end

      def pending_loads
        @pending_loads ||= {}
      end
    end
  end
end
