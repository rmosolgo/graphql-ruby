require "graphql/execution/lazy/lazy_method_map"
require "graphql/execution/lazy/resolve"
module GraphQL
  module Execution
    # This wraps a value which is available, but not yet calculated, like a promise or future.
    #
    # Calling `#value` will trigger calculation & return the "lazy" value.
    #
    # This is an itty-bitty promise-like object, with key differences:
    # - It has only two states, not-resolved and resolved
    # - It has no error-catching functionality
    class Lazy
      # Traverse `val`, lazily resolving any values along the way
      # @param val [Object] A data structure containing mixed plain values and `Lazy` instances
      # @return void
      def self.resolve(val)
        Resolve.resolve(val)
      end

      # Create a {Lazy} which will get its inner value by calling the block
      # @param target [Object]
      # @param method_name [Symbol]
      # @param get_value_func [Proc] a block to get the inner value (later)
      def initialize(target = nil, method_name = nil, &get_value_func)
        if block_given?
          @get_value_func = get_value_func
        else
          @target = target
          @method_name = method_name
        end
        @resolved = false
      end

      # @return [Object] The wrapped value, calling the lazy block if necessary
      def value
        if !@resolved
          @resolved = true
          if @get_value_func
            @value = @get_value_func.call
          else
            @value = @target.public_send(@method_name)
          end
        end
        @value
      rescue GraphQL::ExecutionError => err
        @resolved = true
        @value = err
      end

      # @return [Lazy] A {Lazy} whose value depends on another {Lazy}, plus any transformations in `block`
      def then(&block)
        self.class.new {
          next_val = block.call(value)
        }
      end
    end
  end
end
