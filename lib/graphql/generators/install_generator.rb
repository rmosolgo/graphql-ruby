require 'graphql/generators/base_generator'
module GraphQL
  module Generators
    # Add GraphQL to a Rails app with
    # `rails g graphql:install`.
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
    # app/controllers/graphql_queries_controller.rb
    # ```
    #
    # Add a route for that controller:
    #
    # ```ruby
    # # config/routes.rb
    # post "/graphql", to: "graphql_queries#create"
    # ```
    #
    # Accept a `--relay` option which adds
    # The root `node(id: ID!)` field.
    #
    # Accept a `--graphiql` option which adds
    # `graphiql-rails` to the Gemfile and mounts the
    # engine in `routes.rb` (Should this be the default?)
    class InstallGenerator < BaseGenerator
    end
  end
end
