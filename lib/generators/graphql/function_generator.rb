# frozen_string_literal: true
require "rails/generators/named_base"

module Graphql
  module Generators
    class FunctionGenerator < Rails::Generators::NamedBase
      desc "Create a GraphQL::Function by name"
      source_root File.expand_path('../templates', __FILE__)

      def create_function_file
        template "function.erb", "app/graphql/functions/#{file_name}.rb"
      end
    end
  end
end
