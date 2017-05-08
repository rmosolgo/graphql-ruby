# frozen_string_literal: true
require 'rails/generators/base'
require 'graphql'
require 'active_support'
require 'active_support/core_ext/string/inflections'

module Graphql
  module Generators
    class TypeGeneratorBase < Rails::Generators::Base
      argument :type_name,
        type: :string,
        required: true,
        banner: "TypeName",
        desc: "Name of this object type (expressed as Ruby or GraphQL)"

      # Take a type expression in any combination of GraphQL or Ruby styles
      # and return it in a specified output style
      # TODO: nullability / list with `mode: :graphql` doesn't work
      # @param type_expresson [String]
      # @param mode [Symbol]
      # @return [String]
      def self.normalize_type_expression(type_expression, mode:)
        if type_expression.start_with?("!")
          "!#{normalize_type_expression(type_expression[1..-1], mode: mode)}"
        elsif type_expression.end_with?("!")
          "!#{normalize_type_expression(type_expression[0..-2], mode: mode)}"
        elsif type_expression.start_with?("[") && type_expression.end_with?("]")
          "types[#{normalize_type_expression(type_expression[1..-2], mode: mode)}]"
        elsif type_expression.start_with?("types[") && type_expression.end_with?("]")
          "types[#{normalize_type_expression(type_expression[6..-2], mode: mode)}]"
        elsif type_expression.end_with?("Type")
          normalize_type_expression(type_expression[0..-5], mode: mode)
        elsif type_expression.start_with?("Types::")
          normalize_type_expression(type_expression[7..-1], mode: mode)
        elsif type_expression.start_with?("types.")
          normalize_type_expression(type_expression[6..-1], mode: mode)
        else
          case mode
          when :ruby
            case type_expression
            when "Int", "Float", "Boolean", "String", "ID"
              "types.#{type_expression}"
            else
              "Types::#{type_expression.camelize}Type"
            end
          when :graphql
            type_expression.camelize
          else
            raise "Unexpected normalize mode: #{mode}"
          end
        end
      end

      private

      # @return [String] The user-provided type name, normalized to Ruby code
      def type_ruby_name
        @type_ruby_name ||= self.class.normalize_type_expression(type_name, mode: :ruby)
      end

      # @return [String] The user-provided type name, as a GraphQL name
      def type_graphql_name
        @type_graphql_name ||= self.class.normalize_type_expression(type_name, mode: :graphql)
      end

      # @return [String] The user-provided type name, as a file name (without extension)
      def type_file_name
        @type_file_name ||= "#{type_graphql_name}Type".underscore
      end

      # @return [Array<Array(String, String)>>] User-provided fields, in `(name, Ruby type name)` pairs
      def normalized_fields
        @normalized_fields ||= fields.map { |f|
          name, raw_type = f.split(":", 2)
          [name, self.class.normalize_type_expression(raw_type, mode: :ruby)]
        }
      end
    end
  end
end
