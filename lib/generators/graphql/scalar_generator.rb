# frozen_string_literal: true
require 'generators/graphql/type_generator'

module Graphql
  module Generators
    # Generate a scalar type by given name.
    #
    # ```
    # rails g graphql:scalar Date
    # ```
    class ScalarGenerator < TypeGeneratorBase
      desc "Create a GraphQL::ScalarType with the given name"
      source_root File.expand_path('../templates', __FILE__)

      def create_type_file
        template "scalar.erb", "#{options[:directory]}/types/#{type_file_name}.rb"
      end
    end
  end
end
