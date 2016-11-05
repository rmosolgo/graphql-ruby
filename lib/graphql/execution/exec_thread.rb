module GraphQL
  module Execution
    # One serial stream of execution. One thread runs the initial query,
    # then any deferred frames are restarted with their own threads.
    #
    # - {ExecThread#errors} contains errors during this part of the query
    # - {ExecThread#defers} contains {ExecFrame}s which were marked as `@defer`
    #   and will be executed with their own threads later.
    class ExecThread
      attr_reader :errors, :defers
      def initialize
        @errors = []
        @defers = []
      end
    end
  end
end
