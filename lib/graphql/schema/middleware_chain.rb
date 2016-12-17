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

      # Run the next step in the chain, passing in arguments and handle to the next step
      def invoke(index, arguments)
        steps[index].call(*arguments) { |next_args = arguments| invoke(index + 1, next_args) }
      end
    end
  end
end
