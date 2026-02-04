# frozen_string_literal: true
require 'rails/generators/active_record'

module Graphql
  module Generators
    class DetailedTraceGenerator < ::Rails::Generators::Base
      include ::Rails::Generators::Migration
      desc "Install GraphQL::Tracing::DetailedTrace for your schema"
      source_root File.expand_path('../templates', __FILE__)

      class_option :redis,
        type: :boolean,
        default: false,
        desc: "Use Redis for persistence instead of ActiveRecord"

      def self.next_migration_number(dirname)
        ::ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      def install_detailed_traces

        schema_glob = File.expand_path("app/graphql/*_schema.rb", destination_root)
        schema_file = Dir.glob(schema_glob).first
        if !schema_file
          raise ArgumentError, "Failed to find schema definition file (checked: #{schema_glob.inspect})"
        end
        schema_file_match = /( *)class ([A-Za-z:]+) < GraphQL::Schema/.match(File.read(schema_file))
        schema_name = schema_file_match[2]
        indent = schema_file_match[1] + "  "

        if !options.redis?
          migration_template 'create_graphql_detailed_traces.erb', 'db/migrate/create_graphql_detailed_traces.rb'
        end

        log :add_detailed_traces_plugin
        sentinel = /< GraphQL::Schema\s*\n/m
        code = <<-RUBY
#{indent}use GraphQL::Tracing::DetailedTrace#{options.redis? ? ", redis: raise(\"TODO: pass a connection to a persistent redis database\")" : ""}, limit: 50

#{indent}# When this returns true, DetailedTrace will trace the query
#{indent}# Could use `query.context`, `query.selected_operation_name`, `query.query_string` here
#{indent}# Could call out to Flipper, etc
#{indent}def self.detailed_trace?(query)
#{indent}  rand <= 0.000_1 # one in ten thousand
#{indent}end

        RUBY

        in_root do
          inject_into_file schema_file, code, after: sentinel, force: false
        end

        routes_source = File.read(File.expand_path("config/routes.rb", destination_root))
        already_has_dashboard = routes_source.include?("GraphQL::Dashboard") ||
          routes_source.include?("Schema.dashboard") ||
          routes_source.include?("GraphQL::Pro::Routes::Lazy")

        if (!already_has_dashboard || behavior == :revoke)
          log :route, "GraphQL::Dashboard"
          shell.mute do
            route <<~RUBY
            # TODO: add authorization to this route and expose it in production
            # See https://graphql-ruby.org/pro/dashboard.html#authorizing-the-dashboard
            if Rails.env.development?
              mount GraphQL::Dashboard, at: "/graphql/dashboard", schema: #{schema_name.inspect}
            end

            RUBY
          end
        end
      end
    end
  end
end
