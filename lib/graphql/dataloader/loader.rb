# frozen_string_literal: true

module GraphQL
  class Dataloader
    class Loader
      module BackgroundThreaded
        def sync
          # Promises might be added in the meantime, but they won't be included in this list.
          keys_to_load = @pending_loads.keys - @loaded_values.keys
          p "Future for #{keys_to_load}"
          f = Concurrent::Future.new do
            with_error_handling(keys_to_load) {
              perform(keys_to_load)
            }
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
        dl.loaders[self][key_parts]
      end

      def self.load_all(key, values)
        pending_loads = values.map { |value| load(key, value) }
        Promise.all(pending_loads)
      end

      def initialize(*key)
        @key = key
        @pending_loads = {}
        @loaded_values = {}
      end

      def load(key)
        @pending_loads[key] ||= Promise.new(self)
      end

      def wait
        # Promises might be added in the meantime, but they won't be included in this list.
        keys_to_load = @pending_loads.keys - @loaded_values.keys
        with_error_handling(keys_to_load) {
          perform(keys_to_load)
        }
        nil
      end

      def fulfill(key, value)
        @loaded_values[key] = value
        @pending_loads[key].fulfill(value)
        value
      end

      def fulfilled?(key)
        @loaded_values.key?(key)
      end

      def fulfilled_value_for(key)
        # TODO raise if not loaded?
        @loaded_values[key]
      end

      def perform(values)
        raise NotImplementedError, "`#{self.class}#perform` should call `fulfill(v, loaded_value)` for each of `values`"
      end

      private

      def with_error_handling(keys_to_load)
        yield
      rescue GraphQL::ExecutionError
        # Allow client-facing errors to keep propagating
        raise
      rescue StandardError => cause
        message = "Error from #{self.class}#perform(#{keys_to_load.map(&:inspect).join(", ")}), #{cause.class}: #{cause.message.inspect}"
        # The raised error will automatically be available as `.cause`
        raise GraphQL::Dataloader::LoadError, message, cause.backtrace
      end
    end
  end
end
