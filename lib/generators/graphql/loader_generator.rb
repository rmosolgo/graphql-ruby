# frozen_string_literal: true
require "rails/generators/named_base"

module Graphql
  module Generators
    # @example Generate a `GraphQL::Batch` loader by name.
    #     rails g graphql:loader RecordLoader
    class LoaderGenerator < Rails::Generators::NamedBase
      desc "Create a GraphQL::Batch::Loader by name"
      source_root File.expand_path('../templates', __FILE__)

      def create_loader_file
        template "loader.erb", "app/graphql/loaders/#{file_name}.rb"
      end
    end
  end
end
