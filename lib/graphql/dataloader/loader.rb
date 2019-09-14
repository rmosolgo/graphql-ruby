# frozen_string_literal: true

module GraphQL
  class Dataloader
    class Loader
      class StateError < GraphQL::Error; end

      def self.load(context, key, value)
        dl = context[:dataloader]
        loader = dl.loaders[self][key]
        loader.load(value)
      end

      def initialize(context, key)
        @context = context
        @key = key
        @promises = {}
        @loaded_values = {}
      end

      def load(value)
        @promises[value] ||= GraphQL::Execution::Lazy.new do
          if !@loaded_values.key?(value)
            sync
          end
          @loaded_values[value]
        end
      end

      def sync
        # Promises might be added in the meantime, but they won't be included in this list.
        keys_to_load = @promises.keys - @loaded_values.keys
        resolved_values = perform(keys_to_load)
        keys_to_load.each_with_index do |k, i|
          resolved_value = resolved_values[i]
          @loaded_values[k] = resolved_value
        end
        nil
      end

      def perform(values)
        raise NotImplementedError, "`#{self.class}#perform` should load `values` for `@key` and return an item for each of `values`"
      end
    end
  end
end
