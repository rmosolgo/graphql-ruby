# frozen_string_literal: true
require 'rails/generators'
require 'rails/generators/named_base'
require_relative 'core'

module Graphql
  module Generators
    # TODO: What other options should be supported?
    #
    # @example Generate a `GraphQL::Schema::RelayClassicMutation` by name
    #     rails g graphql:mutation CreatePostMutation
    class OrmMutationsBase < Rails::Generators::NamedBase
      include Core
      include Rails::Generators::ResourceHelpers

      desc "Create a Relay Classic mutation by name"

      class_option :orm, banner: "NAME", type: :string, required: true,
                         desc: "ORM to generate the controller for"

      class_option 'namespaced_types',
        type: :boolean,
        required: false,
        default: false,
        banner: "Namespaced",
        desc: "If the generated types will be namespaced"

      
      def create_root_type
        unless @behavior == :revoke
          create_mutation_root_type
        else
          log :gsub, "#{options[:directory]}/types/mutation_type.rb"
        end     
      end

      def create_mutation_file
        template "mutation_#{operation_type}.erb", File.join(options[:directory], "/mutations/", class_path, "#{file_name}_#{operation_type}.rb")

        sentinel = /class .*MutationType\s*<\s*[^\s]+?\n/m
        in_root do
          inject_into_file "#{options[:directory]}/types/mutation_type.rb", "    field :#{file_name}_#{operation_type}, mutation: Mutations::#{class_name}#{operation_type.classify}\n", after: sentinel, verbose: false, force: false
        end
      end
    end
  end
end
