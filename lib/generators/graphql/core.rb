# frozen_string_literal: true
require 'rails/generators/base'

module Graphql
  module Generators
    module Core
      def insert_root_type(type, name)
        log :add_root_type, type
        sentinel = /GraphQL\:\:Schema\.define do\s*\n/m

        in_root do
          inject_into_file schema_file_path, "  #{type}(Types::#{name})\n", after: sentinel, verbose: false, force: false
        end
      end

      def create_mutation_root_type
        create_dir("app/graphql/mutations")
        template("mutation_type.erb", "app/graphql/types/mutation_type.rb", { skip: true })
        insert_root_type('mutation', 'MutationType')
      end

      def schema_file_path
        "app/graphql/#{schema_name.underscore}.rb"
      end

      def create_dir(dir)
        empty_directory(dir)
        if !options[:skip_keeps]
          create_file("#{dir}/.keep")
        end
      end

      private

      def schema_name
        @schema_name ||= begin
          if options[:schema]
            options[:schema]
          else
            require File.expand_path("config/application", destination_root)
            "#{Rails.application.class.parent_name}Schema"
          end
        end
      end
    end
  end
end
