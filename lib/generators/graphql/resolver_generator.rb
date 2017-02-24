# frozen_string_literal: true
require "rails/generators/named_base"

module Graphql
  module Generators
    # @example Generate a resolve function for a field.
    #     rails g graphql:resolver PostAuthorResolver
    class ResolverGenerator < Rails::Generators::NamedBase
      desc "Create a callable resolver by name"
      source_root File.expand_path('../templates', __FILE__)

      def create_resolver_file
        template "resolver.erb", "app/graphql/resolvers/#{file_name}.rb"
      end
    end
  end
end
