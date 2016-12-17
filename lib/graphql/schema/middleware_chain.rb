# frozen_string_literal: true
module GraphQL
  class Schema
    # Given {steps} and {arguments}, call steps in order, passing `(*arguments, next_step)`.
    #
    # Steps should call `next_step.call` to continue the chain, or _not_ call it to stop the chain.
    class MiddlewareChain
      # @return [Array<#call(*args)>] Steps in this chain, will be called with arguments and `next_middleware`
      attr_reader :steps

      def initialize(steps:)
        @steps = steps
      end

      class ChainCall
        def initialize(chain, next_args, next_offset)
          @chain = chain
          @next_args = next_args
          @next_offset = next_offset
        end

        def call(next_args = @next_args)
          @chain.invoke(@next_offset, next_args)
        end
      end

      # Run the next step in the chain, passing in arguments and handle to the next step
      def invoke(index, arguments)
        next_step = steps[index]
        next_middleware = ChainCall.new(self, arguments, index + 1)
        next_step.call(*arguments, next_middleware)
      end
    end
  end
end
