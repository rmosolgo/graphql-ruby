# frozen_string_literal: true
module GraphQL
  class MigrateExecution
    class AddFuture < Action
      def run
        super
        call_method_on_strategy(:add_future)
      end
    end
  end
end
