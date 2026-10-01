# frozen_string_literal: true
require 'thread'
begin
  require 'concurrent'
rescue LoadError
  # no problem, we'll fallback to our own map
end

module GraphQL
  module Execution
    class Lazy
      # [GraphQL::Schema](rdoc-ref:GraphQL::Schema) uses this to match returned values to lazy resolution methods.
      # Methods may be registered for classes, they apply to its subclasses also.
      # The result of this lookup is cached for future resolutions.
      # Instances of this class are thread-safe.
      # See the schema's `lazy?` configuration to understand which values use this map.
      class LazyMethodMap # :nodoc:
        def initialize(use_concurrent: defined?(Concurrent::Map))
          @storage = use_concurrent ? Concurrent::Map.new : ConcurrentishMap.new
        end

        def initialize_copy(other)
          @storage = other.storage.dup
        end

        # **Parameters**
        #
        # - `lazy_class` (`Class`) — A class which represents a lazy value (subclasses may also be used)
        # - `lazy_value_method` (`Symbol`) — The method to call on this class to get its value
        #
        # :call-seq:
        #   set(Class lazy_class, Symbol lazy_value_method)
        def set(lazy_class, lazy_value_method)
          @storage[lazy_class] = lazy_value_method
        end

        # **Parameters**
        #
        # - `value` (`Object`) — an object which may have a `lazy_value_method` registered for its class or superclasses
        #
        # **Returns**
        #
        # - `Symbol, nil` — The `lazy_value_method` for this object, or nil
        #
        # :call-seq:
        #   get(Object value) -> Symbol | nil
        def get(value)
          @storage.compute_if_absent(value.class) { find_superclass_method(value.class) }
        end

        def each
          @storage.each_pair { |k, v| yield(k, v) }
        end

        protected

        attr_reader :storage

        private

        def find_superclass_method(value_class)
          @storage.each_pair { |lazy_class, lazy_value_method|
            return lazy_value_method if value_class < lazy_class
          }
          nil
        end

        # Mock the Concurrent::Map API
        class ConcurrentishMap
          extend Forwardable
          # Technically this should be under the mutex too,
          # but I know it's only used when the lock is already acquired.
          def_delegators :@storage, :each_pair, :size

          def initialize
            @semaphore = Mutex.new
            # Access to this hash must always be managed by the mutex
            # since it may be modified at runtime
            @storage = {}
          end

          def []=(key, value)
            @semaphore.synchronize {
              @storage[key] = value
            }
          end

          def compute_if_absent(key)
            @semaphore.synchronize {
              @storage.fetch(key) { @storage[key] = yield }
            }
          end

          def initialize_copy(other)
            @semaphore = Mutex.new
            @storage = other.copy_storage
          end

          protected

          def copy_storage
            @semaphore.synchronize {
              @storage.dup
            }
          end
        end
      end
    end
  end
end
