# frozen_string_literal: true
module GraphQL
  class Schema
    # Given {steps} and {arguments}, call steps in order, passing `(*arguments, next_step)`.
    #
    # Steps should call `next_step.call` to continue the chain, or _not_ call it to stop the chain.
    class MiddlewareChain
      extend Forwardable

      # @return [Array<#call(*args)>] Steps in this chain, will be called with arguments and `next_middleware`
      attr_reader :steps, :final_step

      def initialize(steps: [], final_step: nil)
        @steps = steps
        @final_step = final_step
      end

      def initialize_copy(other)
        super
        @steps = other.steps.dup
      end

      def_delegators :@steps, :[], :first, :insert, :delete

      def <<(callable)
        add_middleware(callable)
      end

      def push(callable)
        add_middleware(callable)
      end

      def ==(other)
        steps == other.steps && final_step == other.final_step
      end

      def invoke(arguments)
        invoke_core(0, arguments)
      end

      def concat(callables)
        callables.each { |c| add_middleware(c) }
      end

      private

      def invoke_core(index, arguments)
        if index >= steps.length
          final_step.call(*arguments)
        else
          steps[index].call(*arguments) { |next_args = arguments| invoke_core(index + 1, next_args) }
        end
      end

      def add_middleware(callable)
        # TODO: Stop wrapping callables once deprecated middleware becomes unsupported
        steps << wrap(callable)
      end

      # TODO: Remove this code once deprecated middleware becomes unsupported
      class MiddlewareWrapper
        attr_reader :callable
        def initialize(callable)
          @callable = callable
        end

        def call(*args, &next_middleware)
          callable.call(*args, next_middleware)
        end
      end

      def wrap(callable)
        if BackwardsCompatibility.get_arity(callable) == 6
          GraphQL::Deprecation.warn("Middleware that takes a next_middleware parameter is deprecated (#{callable.inspect}); instead, accept a block and use yield.")
          MiddlewareWrapper.new(callable)
        else
          callable
        end
      end
    end
  end
end
