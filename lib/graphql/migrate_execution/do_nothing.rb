# frozen_string_literal: true
module GraphQL
  class MigrateExecution
    class DoNothing < Strategy
      DESCRIPTION = "These field definitions are already future-compatible. No migration is required."
    end
  end
end
