module GraphQL
  module StaticAnalysis
    # Ride along with a visitor, and as you exit nodes,
    # assign their `path` attribute to the human-friendly
    # selection path to that node. (This way, it will be available for error reporting).
    class PathStack
      def self.mount(visitor)
        stack = self.new
        stack.mount(visitor)
        stack
      end

      def initialize
        @path = []
      end

      def mount(visitor)
      end
    end
  end
end
