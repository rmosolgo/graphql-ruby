# frozen_string_literal: true
module GraphQL
  module Execution
    class Lazy
      # {GraphQL::Schema} uses this to match returned values to lazy resolution methods.
      # Methods may be registered for classes, they apply to its subclasses also.
      # The result of this lookup is cached for future resolutions.
      class LazyMethodMap
        def initialize
          @storage = Hash.new do |h, value_class|
            registered_superclass = h.each_key.find { |lazy_class| value_class < lazy_class }
            if registered_superclass.nil?
              h[value_class] = nil
            else
              h[value_class] = h[registered_superclass]
            end
          end
        end

        # @param lazy_class [Class] A class which represents a lazy value (subclasses may also be used)
        # @param lazy_value_method [Symbol] The method to call on this class to get its value
        def set(lazy_class, lazy_value_method)
          @storage[lazy_class] = lazy_value_method
        end

        # @param value [Object] an object which may have a `lazy_value_method` registered for its class or superclasses
        # @return [Symbol, nil] The `lazy_value_method` for this object, or nil
        def get(value)
          @storage[value.class]
        end

        def each
          @storage.each { |k, v| yield(k,v) }
        end
      end
    end
  end
end
