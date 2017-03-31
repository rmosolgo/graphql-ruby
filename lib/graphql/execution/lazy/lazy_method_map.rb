# frozen_string_literal: true

require 'concurrent'

module GraphQL
  module Execution
    class Lazy
      # {GraphQL::Schema} uses this to match returned values to lazy resolution methods.
      # Methods may be registered for classes, they apply to its subclasses also.
      # The result of this lookup is cached for future resolutions.
      # Instances of this class are thread-safe.
      # @api private
      # @see {Schema#lazy?} looks up values from this map
      class LazyMethodMap
        def initialize
          @storage = Concurrent::Map.new
        end

        # @param lazy_class [Class] A class which represents a lazy value (subclasses may also be used)
        # @param lazy_value_method [Symbol] The method to call on this class to get its value
        def set(lazy_class, lazy_value_method)
          @storage[lazy_class] = lazy_value_method
        end

        # @param value [Object] an object which may have a `lazy_value_method` registered for its class or superclasses
        # @return [Symbol, nil] The `lazy_value_method` for this object, or nil
        def get(value)
          @storage.compute_if_absent(value.class) { find_superclass_method(value.class) }
        end

        def each
          @storage.each { |k, v| yield(k,v) }
        end

        private

        def find_superclass_method(value_class)
          @storage.each { |lazy_class, lazy_value_method|
            return lazy_value_method if value_class < lazy_class
          }
          nil
        end
      end
    end
  end
end
