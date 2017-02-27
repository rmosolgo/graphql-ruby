# frozen_string_literal: true
require 'rails/generators/named_base'

module Graphql
  module Generators
    # TODO: What other options should be supported?
    #
    # @example Generate a `Relay::Mutation` by name
    #     rails g graphql:mutation CreatePostMutation
    class MutationGenerator < Rails::Generators::NamedBase
      desc "Create a Relay mutation by name"
      source_root File.expand_path('../templates', __FILE__)

      def create_mutation_file
        template "mutation.erb", "app/graphql/mutations/#{file_name}.rb"
      end
    end
  end
end
