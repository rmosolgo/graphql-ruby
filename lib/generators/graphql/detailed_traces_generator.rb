# frozen_string_literal: true
require 'rails/generators/active_record'

module Graphql
  module Generators
    class DetailedTracesGenerator < ::Rails::Generators::Base
      include ::Rails::Generators::Migration
      desc "Generates a migration for GraphQL Detailed Tracing ActiveRecord backend"
      source_root File.expand_path('../templates', __FILE__)

      def self.next_migration_number(dirname)
        ::ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      def create_migration_file
        migration_template 'create_graphql_detailed_traces.erb', 'db/migrate/create_graphql_detailed_traces.rb'
      end
    end
  end
end
