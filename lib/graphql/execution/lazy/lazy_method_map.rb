# frozen_string_literal: true
require 'thread'

module GraphQL
  module Execution
    class Lazy
      # {GraphQL::Schema} uses this to match returned values to lazy resolution methods.
      # Methods may be registered for classes, they apply to its subclasses also.
      # The result of this lookup is cached for future resolutions.
      # @api private
      # @see {Schema#lazy?} looks up values from this map
      class LazyMethodMap
        def initialize
          @semaphore = Mutex.new
          # Access to this hash must always be managed by the mutex
          # since it may be modified at runtime
          @storage = Hash.new do |h, value_class|
            @semaphore.synchronize {
              registered_superclass = @storage.each_key.find { |lazy_class| value_class < lazy_class }
              if registered_superclass.nil?
                h[value_class] = nil
              else
                h[value_class] = @storage[registered_superclass]
              end
            }
          end
        end

        def initialize_copy(other)
          @storage = other.storage.dup
        end

        # @param lazy_class [Class] A class which represents a lazy value (subclasses may also be used)
        # @param lazy_value_method [Symbol] The method to call on this class to get its value
        def set(lazy_class, lazy_value_method)
          @semaphore.synchronize {
            @storage[lazy_class] = lazy_value_method
          }
        end

        # @param value [Object] an object which may have a `lazy_value_method` registered for its class or superclasses
        # @return [Symbol, nil] The `lazy_value_method` for this object, or nil
        def get(value)
          @storage[value.class]
        end

        protected

        attr_reader :storage
      end
    end
  end
end
