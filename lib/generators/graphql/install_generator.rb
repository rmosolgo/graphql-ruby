# frozen_string_literal: true
require 'rails/generators/base'
require_relative 'core'

module Graphql
  module Generators
    # Add GraphQL to a Rails app with `rails g graphql:install`.
    #
    # Setup a folder structure for GraphQL:
    #
    # ```
    # - app/
    #   - graphql/
    #     - resolvers/
    #     - types/
    #       - query_type.rb
    #     - loaders/
    #     - mutations/
    #     - {app_name}_schema.rb
    # ```
    #
    # (Add `.gitkeep`s by default, support `--skip-keeps`)
    #
    # Add a controller for serving GraphQL queries:
    #
    # ```
    # app/controllers/graphql_controller.rb
    # ```
    #
    # Add a route for that controller:
    #
    # ```ruby
    # # config/routes.rb
    # post "/graphql", to: "graphql#execute"
    # ```
    #
    # Accept a `--relay` option which adds
    # The root `node(id: ID!)` field.
    #
    # Accept a `--batch` option which adds `GraphQL::Batch` setup.
    #
    # Use `--no-graphiql` to skip `graphiql-rails` installation.
    class InstallGenerator < Rails::Generators::Base
      include Core

      desc "Install GraphQL folder structure and boilerplate code"
      source_root File.expand_path('../templates', __FILE__)

      class_option :schema,
        type: :string,
        default: nil,
        desc: "Name for the schema constant (default: {app_name}Schema)"

      class_option :skip_keeps,
        type: :boolean,
        default: false,
        desc: "Skip .keep files for source control"

      class_option :skip_graphiql,
        type: :boolean,
        default: false,
        desc: "Skip graphiql-rails installation"

      class_option :skip_mutation_root_type,
        type: :boolean,
        default: false,
        desc: "Skip creation of the mutation root type"

      class_option :relay,
        type: :boolean,
        default: false,
        desc: "Include GraphQL::Relay installation"

      class_option :batch,
        type: :boolean,
        default: false,
        desc: "Include GraphQL::Batch installation"

      # These two options are taken from Rails' own generators'
      class_option :api,
        type: :boolean,
        desc: "Preconfigure smaller stack for API only apps"


      GRAPHIQL_ROUTE = <<-RUBY
if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end
RUBY

      def create_folder_structure
        create_dir("app/graphql/types")
        template("schema.erb", schema_file_path)

        # Note: Yuo can't have a schema without the query type, otherwise introspection breaks
        template("query_type.erb", "app/graphql/types/query_type.rb")
        insert_root_type('query', 'QueryType')

        create_mutation_root_type unless options.skip_mutation_root_type?

        template("graphql_controller.erb", "app/controllers/graphql_controller.rb")
        route('post "/graphql", to: "graphql#execute"')

        if options[:batch]
          gem("graphql-batch")
          create_dir("app/graphql/loaders")
        end

        if options.api?
          say("Skipped graphiql, as this rails project is API only")
          say("  You may wish to use GraphiQL.app for development: https://github.com/skevy/graphiql-app")
        elsif !options[:skip_graphiql]
          gem("graphiql-rails", group: :development)

          # This is a little cheat just to get cleaner shell output:
          log :route, 'graphiql-rails'
          shell.mute do
            route(GRAPHIQL_ROUTE)
          end
        end

        if gemfile_modified?
          say "Gemfile has been modified, make sure you `bundle install`"
        end
      end

      private

      def gemfile_modified?
        @gemfile_modified
      end

      def gem(*args)
        @gemfile_modified = true
        super(*args)
      end
    end
  end
end
