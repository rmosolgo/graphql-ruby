# frozen_string_literal: true
require 'generators/graphql/type_generator'

module Graphql
  module Generators
    # Generate an enum type by name, with the given values.
    # To add a `value:` option, add another value after a `:`.
    #
    # ```
    # rails g graphql:enum ProgrammingLanguage RUBY PYTHON PERL PERL6:"PERL"
    # ```
    class EnumGenerator < TypeGeneratorBase
      desc "Create a GraphQL::EnumType with the given name and values"
      source_root File.expand_path('../templates', __FILE__)

      argument :values,
        type: :array,
        default: [],
        banner: "value{:ruby_value} value{:ruby_value} ...",
        desc: "Values for this enum (if present, ruby_value will be inserted verbatim)"

      def create_type_file
        template "enum.erb", "#{options[:directory]}/types/#{type_file_name}.rb"
      end

      private

      def prepared_values
        values.map { |v| v.split(":", 2) }
      end
    end
  end
end
