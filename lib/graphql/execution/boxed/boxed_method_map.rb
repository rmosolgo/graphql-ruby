module GraphQL
  module Execution
    class Boxed
      class BoxMethodMap
        def initialize
          @storage = {}
        end

        # @param boxed_class [Class] A class which represents a boxed value (subclasses may also be used)
        # @param boxed_value_method [Symbol] The method to call on this class to get its value
        def set(boxed_class, boxed_value_method)
          @storage[boxed_class] = boxed_value_method
        end

        # @param value [Object] an object which may have a `boxed_value_method` registered for its class or superclasses
        # @return [Symbol, nil] The `boxed_value_method` for this object, or nil
        def get(value)
          if @storage.key?(value.class)
            @storage[value.class]
          else
            value_class = value.class
            registered_superclass = @storage.each_key.find { |boxed_class| value_class < boxed_class }
            @storage[value_class] = @storage[registered_superclass]
          end
        end
      end
    end
  end
end
