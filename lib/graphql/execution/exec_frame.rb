module GraphQL
  module Execution
    # One step of execution. Each step in execution gets its own frame.
    #
    # - {ExecFrame#node} is the IRep node which is being interpreted
    # - {ExecFrame#path} is like a stack trace, it is used for patching deferred values
    # - {ExecFrame#value} is the object being exposed by GraphQL at this point
    # - {ExecFrame#type} is the GraphQL type which exposes {#value} at this point
    class ExecFrame
      attr_reader :node, :path, :type, :value
      def initialize(node:, path:, type:, value:)
        @node = node
        @path = path
        @type = type
        @value = value
      end
    end
  end
end
