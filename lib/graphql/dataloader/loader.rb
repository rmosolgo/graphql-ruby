# frozen_string_literal: true

module GraphQL
  class Dataloader
    class Loader
      def self.load(context, *key, value)
        self.for(context, *key).load(value)
      end

      def self.for(context, *key_parts)
        dl = context[:dataloader]
        dl.loaders[self][key_parts]
      end

      def self.load_all(context, key, values)
        GraphQL::Execution::Lazy.all(values.map { |value| load(context, key, value) })
      end

      def initialize(context, *key)
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
          # TODO raise if key is missing?
          @loaded_values[value]
        end
      end

      def sync
        # Promises might be added in the meantime, but they won't be included in this list.
        keys_to_load = @promises.keys - @loaded_values.keys
        perform(keys_to_load)
        nil
      end

      def fulfill(key, value)
        @loaded_values[key] = value
      end

      def fulfilled?(key)
        @loaded_values.key?(key)
      end

      def perform(values)
        raise NotImplementedError, "`#{self.class}#perform` should load `values` for `@key` and return an item for each of `values`"
      end
    end
  end
end
