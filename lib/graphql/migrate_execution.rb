# frozen_string_literal: true
require "prism"
require "graphql/migrate_execution/action"
require "graphql/migrate_execution/add_future"
require "graphql/migrate_execution/remove_legacy"
require "graphql/migrate_execution/analyze"

require "graphql/migrate_execution/field_definition"
require "graphql/migrate_execution/resolver_method"
require "graphql/migrate_execution/type_definition"
require "graphql/migrate_execution/visitor"

require "graphql/migrate_execution/strategy"
require "graphql/migrate_execution/implicit"
require "graphql/migrate_execution/do_nothing"
require "graphql/migrate_execution/resolve_each"
require "graphql/migrate_execution/resolve_static"
require "graphql/migrate_execution/not_implemented"

module GraphQL
  class MigrateExecution
    def initialize(filepath)
      @filepath = filepath
    end

    def run
      source = File.read(@filepath)
      file_migrate = Analyze.new(@filepath, source)
      puts file_migrate.run
    end
  end
end
