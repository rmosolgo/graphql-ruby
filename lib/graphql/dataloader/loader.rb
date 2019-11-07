# frozen_string_literal: true

module GraphQL
  class Dataloader
    class Loader
      # TODO: this is basically a reimplementation of Promise.rb
      # Should I just take on that dependency, or is there a value in a
      # custom implementation?
      class PendingLoad
        attr_writer :loaded
        attr_reader :pending_thens

        def initialize(loader, key)
          @loader = loader
          @key = key
          @loaded = false
          @pending_thens = []
        end

        def sync
          if !@loaded
            @loaded = true
            if @loader.nil?
              binding.pry
            end
            @loader.sync
          end
          @loader.fulfilled_value_for(@key)
        end

        def value
          if !@fully_loaded
            @fully_loaded = true
            v = sync
            if v.is_a?(PendingLoad)
              v = v.value
            end
            @fully_loaded_value = v
          end
          @fully_loaded_value
        end

        def then(&next_block)
          pending_then = ThenBlock.new(self, next_block)
          if !@loaded
            @pending_thens << pending_then
          end
          pending_then
        end
      end

      class ThenBlock < PendingLoad
        def initialize(pending_load, then_block)
          @pending_load = pending_load
          @then_block = then_block
          @loaded = false
          @pending_thens = []
          @value = nil
        end

        def sync
          if !@loaded
            @loaded = true
            @value = @then_block.call(@pending_load.sync)
            @pending_thens.each(&:sync)
          end
          @value
        end
      end

      class AllPendingLoads < PendingLoad
        def initialize(pending_loads)
          @loaded = false
          @value = nil
          @pending_loads = pending_loads
          @pending_thens = []
        end

        def sync
          if !@loaded
            @loaded = true
            @value = @pending_loads.map(&:sync)
            @pending_thens.each(&:sync)
          end
          @value
        end
      end

      def self.load(context, *key, value)
        self.for(context, *key).load(value)
      end

      def self.for(context, *key_parts)
        dl = context[:dataloader]
        dl.loaders[self][key_parts]
      end

      def self.load_all(context, key, values)
        pending_loads = values.map { |value| load(context, key, value) }
        AllPendingLoads.new(pending_loads)
      end

      def initialize(context, *key)
        @context = context
        @key = key
        @promises = {}
        @loaded_values = {}
      end

      def load(key)
        @promises[key] ||= PendingLoad.new(self, key)
      end

      def sync
        # Promises might be added in the meantime, but they won't be included in this list.
        keys_to_load = @promises.keys - @loaded_values.keys
        perform(keys_to_load)
        nil
      end

      def fulfill(key, value)
        @loaded_values[key] = value
        @promises[key].loaded = true
        @promises[key].pending_thens.each(&:sync)
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
    end
  end
end
