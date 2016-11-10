require "graphql/execution/boxed/boxed_method_map"
require "graphql/execution/boxed/unbox"
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
    end
  end
end
