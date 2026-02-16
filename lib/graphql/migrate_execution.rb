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
require "graphql/migrate_execution/dataloader_all"
require "graphql/migrate_execution/dataloader_association"
require "graphql/migrate_execution/dataloader_batch"
require "graphql/migrate_execution/dataloader_manual"

require "graphql/migrate_execution/not_implemented"

module GraphQL
  class MigrateExecution
    def initialize(glob, skip_description: false)
      @glob = glob
      @skip_description = skip_description
    end

    attr_reader :skip_description

    def run
      Dir.glob(@glob).each do |filepath|
        source = File.read(filepath)
        file_migrate = Analyze.new(self, filepath, source)
        puts file_migrate.run
      end
    end
  end
end
