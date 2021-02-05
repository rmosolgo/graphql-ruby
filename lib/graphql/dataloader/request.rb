# frozen_string_literal: true
module GraphQL
  class Dataloader
    # @see Source#request which returns an instance of this
    class Request
      def initialize(source, key)
        @source = source
        @key = key
      end

      # Call this method to cause the current Fiber to wait for the results of this request.
      #
      # @return [Object] the object loaded for `key`
      def load
        @source.load(@key)
      end
    end
  end
end
