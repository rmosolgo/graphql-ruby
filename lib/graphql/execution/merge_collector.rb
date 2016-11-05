module GraphQL
  module Execution
    class MergeCollector
      attr_reader :result
      def initialize
        @result = nil
      end

      def patch(path:, value:)
        if @result.nil?
          # first patch
          @result = value
        else
          last = path.pop
          target = @result
          path.each do |key|
            target = target[key]
          end
          target[last] = value
        end
      end
    end
  end
end
