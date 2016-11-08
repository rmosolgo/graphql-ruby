module GraphQL
  module Execution
    # This wraps a value which is available, but not yet calculated, like a promise or future.
    #
    # Calling `#value` will trigger calculation & return the "boxed" value.
    #
    # This is an itty-bitty promise-like object, with key differences:
    # - It has only two states, not-resolved and resolved
    # - It has no error-catching functionality
    class Boxed
      # Traverse `val`, lazily unboxing any values along the way
      # @param val [Object] A data structure containing mixed unboxed values and `Boxed` instances
      # @return void
      def self.unbox(val)
        b = Unbox.unbox_in_place(val)
        Unbox.deep_sync(b)
      end

      # Create a `Boxed` which will get its inner value by calling the block
      # @param get_value_func [Proc] a block to get the inner value (later)
      def initialize(&get_value_func)
        @get_value_func = get_value_func
        @resolved = false
      end

      # @return [Object] The wrapped value, calling the lazy block if necessary
      def value
        if !@resolved
          @resolved = true
          @value = @get_value_func.call
        end
        @value
      end

      # @return [Boxed] A Boxed whose value depends on another Boxed, plus any transformations in `block`
      def then(&block)
        self.class.new {
          next_val = block.call(value)
        }
      end

      # Helpers for dealing with data structures containing {Boxed} instances
      module Unbox
        # Mutate `value`, replacing {Boxed} instances in place with their resolved values
        # @return [void]
        def self.unbox_in_place(value)
          boxes = []

          each_box(value) do |obj, key, value|
            inner_b = value.then do |inner_v|
              obj[key] = inner_v
              unbox_in_place(inner_v)
            end
            boxes.push(inner_b)
          end

          Boxed.new { boxes.map(&:value) }
        end

        # If `value` is a collection, call `block`
        # with any {Boxed} instances in the collection
        # @return [void]
        def self.each_box(value, &block)
          case value
          when Hash
            value.each do |k, v|
              if v.is_a?(Boxed)
                yield(value, k, v)
              else
                each_box(v, &block)
              end
            end
          when Array
            value.each_with_index do |v, i|
              if v.is_a?(Boxed)
                yield(value, i, v)
              else
                each_box(v, &block)
              end
            end
          end
        end

        # Traverse `val`, triggering resolution for each {Boxed}.
        # These {Boxed}s are expected to mutate their owner data structures
        # during resolution! (They're created with the `.then` calls in `unbox_in_place`).
        # @return [void]
        def self.deep_sync(val)
          case val
          when Boxed
            deep_sync(val.value)
          when Array
            val.each { |v| deep_sync(v) }
          when Hash
            val.each { |k, v| deep_sync(v) }
          end
        end
      end

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
