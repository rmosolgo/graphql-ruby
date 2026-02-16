# frozen_string_literal: true
module GraphQL
  class MigrateExecution
    class DataloadAll < Strategy
      DESCRIPTION = <<~DESC
      These fields can use a `dataload:` option.
      DESC
    end
  end
end
