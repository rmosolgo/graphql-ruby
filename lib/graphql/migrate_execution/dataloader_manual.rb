# frozen_string_literal: true
module GraphQL
  class MigrateExecution
    class DataloaderManual < Strategy
      DESCRIPTION = <<~DESC
      These fields use Dataloader in a way that can't be automatically migrated. You'll have to migrate them manually.
      If you have a lot of these, consider opening up an issue on GraphQL-Ruby -- maybe we can find a way to programmatically support them.
      DESC
    end
  end
end
