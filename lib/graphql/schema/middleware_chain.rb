module GraphQL
  class Schema
    # Given {steps} and {arguments}, call steps in order, passing `(*arguments, next_step)`.
    #
    # Steps should call `next_step.call` to continue the chain, or _not_ call it to stop the chain.
    class MiddlewareChain
      # @return [Array<#call(*args)>] Steps in this chain, will be called with arguments and `next_middleware`
      attr_reader :steps

      # @return [Array] Arguments passed to steps (followed by `next_middleware`)
      attr_reader :arguments

      ### Ruby 1.9.3 unofficial support
      # def initialize(steps:, arguments:)
      def initialize(options = {})
        steps = options[:steps]
        arguments = options[:arguments]

        # We're gonna destroy this array, so copy it:
        @steps = steps.dup
        @arguments = arguments
      end

      # Run the next step in the chain, passing in arguments and handle to the next step
      def call(next_arguments = @arguments)
        @arguments = next_arguments
        next_step = steps.shift
        next_middleware = self
        next_step.call(*arguments, next_middleware)
      end
    end
  end
end
