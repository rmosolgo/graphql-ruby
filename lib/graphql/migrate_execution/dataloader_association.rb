# frozen_string_literal: true
module GraphQL
  class MigrateExecution
    class DataloaderAssociation < Strategy
      DESCRIPTION = <<~DESC
      These fields can use a `dataload_association:` option.
      DESC
    end
  end
end
