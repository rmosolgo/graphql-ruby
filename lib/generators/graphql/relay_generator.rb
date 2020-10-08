# frozen_string_literal: true
require 'rails/generators/base'
require_relative 'core'

module Graphql
  module Generators
    class Relay < Rails::Generators::Base
      include Core

      def install_relay
        template("base_connection.erb", "#{options[:directory]}/types/base_connection.rb")
        template("base_edge.erb", "#{options[:directory]}/types/base_edge.rb")
        connectionable_type_files = {
          "#{options[:directory]}/types/base_object.rb" => /class .*BaseObject\s*<\s*[^\s]+?\n/m,
          "#{options[:directory]}/types/base_union.rb" =>  /class .*BaseUnion\s*<\s*[^\s]+?\n/m
          "#{options[:directory]}/types/base_interface.rb"  /include GraphQL::Schema::Interface\n/m
        }
        in_root do
          connection_type_class.each do |type_class_file, sentinel|
            inject_into_file type_class_file, "    connection_type_class(Types::BaseConnection)\n", after: sentinel, verbose: false, force: false
            inject_into_file type_class_file, "    edge_type_class(Types::BaseEdge)\n", after: sentinel, verbose: false, force: false
          end
        end
      end
    end
  end
end
