module GraphQL
  module Execution
    class Lazy
      # {GraphQL::Schema} uses this to match returned values to lazy resolution methods.
      # Methods may be registered for classes, they apply to its subclasses also.
      # The result of this lookup is cached for future resolutions.
      class LazyMethodMap
        def initialize
          @storage = {}
        end

        # @param lazy_class [Class] A class which represents a lazy value (subclasses may also be used)
        # @param lazy_value_method [Symbol] The method to call on this class to get its value
        def set(lazy_class, lazy_value_method)
          @storage[lazy_class] = lazy_value_method
        end

        # @param value [Object] an object which may have a `lazy_value_method` registered for its class or superclasses
        # @return [Symbol, nil] The `lazy_value_method` for this object, or nil
        def get(value)
          if @storage.key?(value.class)
            @storage[value.class]
          else
            value_class = value.class
            registered_superclass = @storage.each_key.find { |lazy_class| value_class < lazy_class }
            @storage[value_class] = @storage[registered_superclass]
          end
        end
      end
    end
  end
end
