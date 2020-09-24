# frozen_string_literal: true
require "graphql/execution/lazy/lazy_method_map"
require "graphql/execution/lazy/resolve"

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

      attr_reader :path, :field

      # Create a {Lazy} which will get its inner value from `source,` and/or by calling the block
      # @param source [<#wait>]
      # @param path [Array<String, Integer>]
      # @param field [GraphQL::Schema::Field]
      # @param then_block [Proc] a block to get the inner value (later)
      def initialize(source = nil, path: nil, field: nil, &then_block)
        @source = source || :__block_only__
        @caller = caller(2, 1).first
        @then_block = then_block
        @resolved = false
        @value = nil
        @pending_lazies = nil
        @path = path
        @field = field
      end

      # @return [Object] The wrapped value, calling the lazy block if necessary
      def value
        wait
        @value
      end

      alias :sync :value

      # resolve this lazy's dependencies as long as one can be found
      # @return [void]
      def wait
        if !@resolved
          if @source == :__block_only__
            fulfill(nil)
          else
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
        end
      rescue GraphQL::Dataloader::LoadError => err
        local_err = err.dup
        query = Dataloader.current.current_query
        local_err.graphql_path = query.context[:current_path]
        op_name = query.selected_operation_name || query.selected_operation.operation_type || "query"
        local_err.message = err.message.sub("),", ") at #{op_name}.#{local_err.graphql_path.join(".")},")
        raise local_err
      end

      def resolved?
        @resolved
      end

      # TODO also reject?
      # TODO better api than `call_then = true`
      def fulfill(value, call_then = true )
        if @resolved
          return
        end

        if @then_block && call_then
          value = @then_block.call(value)
        end

        if value.is_a?(self.class)
          if value.resolved?
            fulfill(value.value)
          else
            @source = value
            # set this so it can be returned by {#value}, even though the it's not resolved
            # That's because `Lazy::Resolve` uses `value` to keep resolving recursively
            @value = value
            value.subscribe(self, false)
          end
        else
          @source = nil
          @resolved = true
          @value = value
          if @pending_lazies
            lazies = @pending_lazies
            @pending_lazies = nil
            lazies.each { |lazy, call_then| lazy.fulfill(value, call_then) }
          end
        end
      end

      # @return [Lazy] A {Lazy} whose value depends on another {Lazy}, plus any transformations in `block`
      def then(&block)
        new_lazy = self.class.new(self, &block)
        subscribe(new_lazy)
        new_lazy
      end

      def subscribe(other_lazy, call_then = true )
        @pending_lazies ||= []
        @pending_lazies.push([other_lazy, call_then])
      end

      def self.all(maybe_lazy)
        group = Group.new(maybe_lazy)
        group.lazy
      end

      def inspect
        "#<#{self.class.name} from \"#{@caller}\" #{@field || "unknown-field"} / #{@path || "unknown-path"} @resolved=#{@resolved} @value=#{@value.inspect}>"
      end

      # This can be used for fields which _had no_ lazy results
      # @api private
      NullResult = Lazy.new(){}
      NullResult.value

      class Group
        attr_reader :lazy

        def initialize(maybe_lazies)
          @lazy = Lazy.new(self)
          @maybe_lazies = maybe_lazies
          @waited = false
        end

        def wait
          if !@waited
            @waited = true
            results = @maybe_lazies.map { |maybe_lazy|
              if maybe_lazy.respond_to?(:wait)
                maybe_lazy.wait
                maybe_lazy.value
              else
                maybe_lazy
              end
            }
            lazy.fulfill(results)
          end
        end
      end
    end
  end
end
