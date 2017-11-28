# frozen_string_literal: true
require "rails/generators/named_base"
require_relative "core"

module Graphql
  module Generators
    class FunctionGenerator < Rails::Generators::NamedBase
      include Core

      desc "Create a GraphQL::Function by name"
      source_root File.expand_path('../templates', __FILE__)

      def create_function_file
        template "function.erb", "#{options[:directory]}/functions/#{file_path}.rb"
      end
    end
  end
end
