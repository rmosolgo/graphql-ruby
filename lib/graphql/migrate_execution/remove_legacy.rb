# frozen_string_literal
module GraphQL
  class MigrateExecution
    class RemoveLegacy < Action
      def run
        super
        call_method_on_strategy(:remove_legacy)
      end
    end
  end
end
