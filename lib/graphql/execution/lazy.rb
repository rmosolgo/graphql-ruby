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

      # Create a {Lazy} which will get its inner value by calling the block
      # @param value_proc [Proc] a block to get the inner value (later)
      def initialize(original = nil, value:, exec:)
        @original = original
        @value_proc = value
        @exec_proc = exec
        @resolved = false
      end

      def execute
        return if @resolved

        exec =
          begin
            e = @exec_proc.call
            if e.is_a?(Lazy)
              e = e.execute
            end
            e
          rescue GraphQL::ExecutionError => err
            err
          end

        if exec.is_a?(StandardError)
          raise exec
        end
      end

      # @return [Object] The wrapped value, calling the lazy block if necessary
      def value
        if !@resolved
          @resolved = true
          @value = begin
            v = @value_proc.call
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
        self.class.new(
          value: -> { yield(value) },
          exec: -> { execute }
        )
      end

      # @param lazies [Array<Object>] Maybe-lazy objects
      # @return [Lazy] A lazy which will sync all of `lazies`
      def self.all(lazies)
        self.new(
          value: -> { lazies.map { |l| l.is_a?(Lazy) ? l.value : l } },
          exec: -> { lazies.each { |l| l.is_a?(Lazy) ? l.execute : l } }
        )
      end

      # This can be used for fields which _had no_ lazy results
      # @api private
      NullResult = Lazy.new(value: -> {}, exec: -> {})
      NullResult.value
    end
  end
end
