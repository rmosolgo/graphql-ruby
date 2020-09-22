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

        # @return [GraphQL::Query]
        attr_reader :query

        def initialize(loader, key, query:)
          @loader = loader
          @key = key
          @query = query
          @loaded = false
          @pending_thens = []
          @fully_loaded = false
          @fully_loaded_value = nil
          @raised = false
        end

        def sync
          if !@loaded
            @loaded = true
            @loader.sync
          end
          @loader.fulfilled_value_for(@key)
        rescue GraphQL::Dataloader::LoadError => err
          local_err = err.dup
          path = query.context[:current_path]
          op_name = query.selected_operation_name || query.selected_operation.operation_type || "query"
          local_err.message = err.message + " at #{op_name}.#{path.join(".")}"
          local_err.graphql_path = path
          raise local_err
        end

        def value
          if !@fully_loaded
            @fully_loaded = true
            @fully_loaded_value = begin
              v = sync
              if v.is_a?(PendingLoad)
                v = v.value
              end
              v
            rescue StandardError => err
              @raised = true
              err
            end
          end

          if @raised
            raise @fully_loaded_value
          else
            @fully_loaded_value
          end
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

        def query
          @pending_load.query
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

        # TODO better than nothing, but not a great implementation
        def query
          pending_loads.first.query
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
        AllPendingLoads.new(pending_loads)
      end

      def initialize(context, *key)
        @context = context
        @key = key
        @promises = {}
        @loaded_values = {}
      end

      def load(key)
        @promises[key] ||= begin
          # @context is the multiplex context, get the currently-running query
          query = @context[:current_query]
          PendingLoad.new(self, key, query: query)
        end
      end

      def threaded?
        false
      end

      def sync
        # Promises might be added in the meantime, but they won't be included in this list.
        keys_to_load = @promises.keys - @loaded_values.keys
        if threaded?
          Concurrent::Future.execute do
            with_error_handling(keys_to_load) {
              perform(keys_to_load)
            }
          end
        else
          with_error_handling(keys_to_load) {
            perform(keys_to_load)
          }
        end
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

      private

      def with_error_handling(keys_to_load)
        yield
      rescue GraphQL::ExecutionError
        # Allow client-facing errors to keep propagating
        raise
      rescue StandardError
        # The raised error will automatically be available as `.cause`
        raise GraphQL::Dataloader::LoadError, "Error from #{self.class}#perform(#{keys_to_load.map(&:inspect).join(", ")})"
      end
    end
  end
end
