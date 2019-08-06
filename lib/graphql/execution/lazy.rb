# frozen_string_literal: true
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
    # @api private
    class Lazy
      # Traverse `val`, lazily resolving any values along the way
      # @param val [Object] A data structure containing mixed plain values and `Lazy` instances
      # @return void
      def self.resolve(val)
        Resolve.resolve(val)
      end

      attr_reader :path, :field

      # Create a {Lazy} which will get its inner value by calling the block
      # @param path [Array<String, Integer>]
      # @param field [GraphQL::Schema::Field]
      # @param get_value_func [Proc] a block to get the inner value (later)
      def initialize(path: nil, field: nil, &get_value_func)
        @get_value_func = get_value_func
        @resolved = false
        @path = path
        @field = field
      end

      # @return [Object] The wrapped value, calling the lazy block if necessary
      def value
        if !@resolved
          @resolved = true
          @value = begin
            v = @get_value_func.call
            if v.is_a?(Lazy)
              v = v.value
            end
            v
          rescue GraphQL::ExecutionError => err
            err
          end
        end

        if @value.is_a?(StandardError)
          raise @value
        else
          @value
        end
      end

      # @return [Lazy] A {Lazy} whose value depends on another {Lazy}, plus any transformations in `block`
      def then
        self.class.new {
          yield(value)
        }
      end

      # @param lazies [Array<Object>] Maybe-lazy objects
      # @return [Lazy] A lazy which will sync all of `lazies`
      def self.all(lazies)
        self.new {
          lazies.map { |l| l.is_a?(Lazy) ? l.value : l }
        }
      end

      # This can be used for fields which _had no_ lazy results
      # @api private
      NullResult = Lazy.new(){}
      NullResult.value
    end
  end
end
