# frozen_string_literal: true
module GraphQL
  class MigrateExecution
    class DataloaderBatch < Strategy
      DESCRIPTION = <<~DESC
      These fields can be rewritten to dataload in a `resolve_batch:` method.
      DESC
    end
  end
end
