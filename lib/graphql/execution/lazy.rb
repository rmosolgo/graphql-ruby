# frozen_string_literal: true
require "graphql/execution/lazy/lazy_method_map"
require "graphql/execution/lazy/resolve"
require "graphql/execution/lazy/group"

module GraphQL
  module Execution
    # This wraps a value which is available, but not yet calculated, like a promise or future.
    #
    # Calling `#value` will trigger calculation & return the "lazy" value.
    #
    # This is a promise-like object, with key differences:
    # - It has only two states, not-resolved and resolved
    # - It has no error-catching functionality
    class Lazy
      # Traverse `val`, lazily resolving any values along the way
      # @param val [Object] A data structure containing mixed plain values and `Lazy` instances
      # @return void
      def self.resolve(val)
        Resolve.resolve(val)
      end

      # If `maybe_lazy` is a Lazy, sync it recursively. (Never returns another Lazy)
      def self.sync(maybe_lazy)
        if maybe_lazy.is_a?(Lazy)
          sync(maybe_lazy.value)
        else
          maybe_lazy
        end
      end

      # @param maybe_lazies [Array<Lazy, Object>]
      # @return [Lazy] A single lazy wrapping any number of maybe-lazy objects
      def self.all(maybe_lazies)
        group = Group.new(maybe_lazies)
        group.lazy
      end

      class OnlyBlockSource
        def initialize(block, promise)
          @block = block
          @promise = promise
        end

        def wait
          value = @block.call
          @promise.fulfill(value)
        end
      end

      # @return [Array<String, Integer>] The runtime path where this lazy was created
      attr_reader :path

      # @return [GraphQL::Schema::Field] The field that was executing when this lazy was created
      attr_reader :field

      # Create a {Lazy} which will get its inner value from `source,` and/or by calling the block
      # @param source [<#wait>] Some object that this Lazy depends on, if there is one
      # @param path [Array<String, Integer>]
      # @param field [GraphQL::Schema::Field]
      # @param then_block [Proc] a block to get the inner value (later)
      def initialize(source = nil, path: nil, field: nil, caller_offset: 0, &then_block)
        @caller = caller(2 + caller_offset, 1).first
        if source.nil?
          # This lazy is just a deferred block
          @source = OnlyBlockSource.new(then_block, self)
          @then_block = nil
        else
          @source = source
          @then_block = then_block
        end
        @resolved = false
        @value = nil
        @pending_lazies = nil
        @path = path
        @field = field
      end

      # @return [Object] The wrapped value, calling the lazy block if necessary
      # @raise [StandardError] if this lazy was {#fulfill}ed with an error
      def value
        wait
        if @value.is_a?(StandardError)
          raise @value
        else
          @value
        end
      end

      alias :sync :value

      # resolve this lazy's dependencies as long as one can be found
      # @return [void]
      def wait
        if !@resolved
          while (current_source = @source)
            current_source.wait
            # Only care if these are the same object,
            # which shows that the lazy didn't start
            # waiting on something else
            if current_source.equal?(@source)
              break
            end
          end
        end
      rescue GraphQL::Dataloader::LoadError => err
        raise tag_error(err)
      end

      # @return [Boolean] true if this value has received a finished value, by a direct call to {#fulfill} or by {#wait}, which might trigger a call to {#fulfill}
      def resolved?
        @resolved
      end

      # Set this Lazy's resolved value, if it hasn't already been resolved.
      #
      # @param value [Object] If this is a `StandardError`, it will be raised by {#value}
      # @param call_then [Boolean] When `true`, this Lazy's `@then_block` will be called with `value` before passing it along
      # @return [void]
      def fulfill(value, call_then: false)
        if @resolved
          return
        end

        if call_then && @then_block
          value = @then_block.call(value)
        end

        if value.is_a?(Lazy)
          if value.resolved?
            fulfill(value.value)
          else
            @source = value
            value.subscribe(self, call_then: false)
          end
        else
          @source = nil
          @resolved = true
          @value = value
          if @pending_lazies
            non_error = !value.is_a?(StandardError)
            lazies = @pending_lazies
            @pending_lazies = nil
            lazies.each { |lazy, call_then|
              lazy.fulfill(value, call_then: non_error && call_then)
            }
          end
        end
      end

      # @return [Lazy] A {Lazy} whose value depends on `self`, plus any transformations in `block`
      def then(&block)
        new_lazy = self.class.new(self, &block)
        subscribe(new_lazy, call_then: true)
        new_lazy
      end

      def inspect
        "#<#{self.class.name}##{object_id} from #{@caller.inspect} / #{@field.respond_to?(:path) ? "#{@field.path} " : ""}#{@path ? "#{@path} " : ""}@source=#<#{@source.class}> @resolved=#{@resolved} @value=#{@value.inspect}>"
      end

      protected

      # Add `other_lazy` to this Lazy's dependencies. It will be `.fulfill(...)`ed with the value of this lazy, eventually.
      def subscribe(other_lazy, call_then:)
        @pending_lazies ||= []
        @pending_lazies.push([other_lazy, call_then])
      end

      private

      # Copy `err` and update the copy with Lazy-specfic details.
      # (The error probably came from a Source, which has any number of pending Lazies.)
      # @param err [Dataloader::LoadError]
      # @return [Dataloader::LoadError] An updated copy
      def tag_error(err)
        local_err = err.dup
        query = Dataloader.current.current_query
        local_err.graphql_path = query.context[:current_path]
        op_name = query.selected_operation_name || query.selected_operation.operation_type || "query"
        local_err.message = err.message.sub("),", ") at #{op_name}.#{local_err.graphql_path.join(".")},")
        local_err
      end

      # This can be used for fields which _had no_ lazy results
      # @api private
      NullResult = Lazy.new(){}
      NullResult.value
    end
  end
end
