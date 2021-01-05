# frozen_string_literal: true
module GraphQL
  class Dataloader
    # @see Source#request_all which returns an instance of this.
    class RequestAll < Request
      def initialize(source, keys)
        @source = source
        @keys = keys
      end

      # Call this method to cause the current Fiber to wait for the results of this request.
      #
      # @return [Array<Object>] One object for each of `keys`
      def load
        if @keys.any? { |k| !@source.results.key?(k) }
          @source.sync
        end
        @keys.map { |k| @source.results[k] }
      end
    end
  end
end
