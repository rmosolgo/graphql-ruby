module GraphQL
  module Execution
    module Batch
      def self.resolve(item_arg, func)
        BatchResolve.new(item_arg, func )
      end

      class BatchLoader
        attr_reader :func, :args
        def initialize(func, args)
          @func = func
          @args = args
        end
      end

      class BatchResolve
        attr_reader :item_arg, :func
        def initialize(item_arg, func)
          @item_arg = item_arg
          @func = func
        end
      end

      class Accumulator
        def initialize
          @storage = init_storage
        end

        def register(loader, group_args, path, batch_resolve)
          key = [loader, group_args]
          callback = [path, batch_resolve.func]
          @storage[key][batch_resolve.item_arg] << callback
        end

        def any?
          @storage.any?
        end

        def resolve_all(&block)
          batches = @storage
          @storage = init_storage
          batches.each do |(loader, group_args), item_arg_callbacks|
            item_args = item_arg_callbacks.keys
            loader.call(*group_args, item_args) { |item_arg, result|
              callbacks = item_arg_callbacks[item_arg]
              callbacks.each do |(path, func)|
                next_result = func.nil? ? result : func.call(result)
                yield(path, next_result)
              end
            }
          end
        end

        private

        def init_storage
          # { [loader, group_args] => { item_arg => [callback, ...] } }
          Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = [] } }
        end
      end
    end
  end
end
