# frozen_string_literal: true
require 'generators/graphql/type_generator'

module Graphql
  module Generators
    # Generate an object type by name,
    # with the specified fields.
    #
    # ```
    # rails g graphql:object PostType name:String!
    # ```
    #
    # Add the Node interface with `--node`.
    class ObjectGenerator < TypeGeneratorBase
      desc "Create a GraphQL::ObjectType with the given name and fields"
      source_root File.expand_path('../templates', __FILE__)

      argument :custom_fields,
               type: :array,
               default: [],
               banner: "name:type name:type ...",
               desc: "Fields for this object (type may be expressed as Ruby or GraphQL)"

      class_option :node,
                   type: :boolean,
                   default: false,
                   desc: "Include the Relay Node interface"

      def create_type_file
        template "object.erb", "#{options[:directory]}/types/#{type_file_name}.rb"
      end

      def fields
        columns = []
        columns += klass.columns.map { |c| generate_column_string(c) } if class_exists?
        columns + custom_fields
      end

      def self.normalize_type_expression(type_expression, mode:, null: true)
        case type_expression
        when "Text"
          ["String", null]
        when "Decimal"
          ["Float", null]
        when "DateTime", "Datetime"
          ["GraphQL::Types::ISO8601DateTime", null]
        when "Date"
          ["GraphQL::Types::ISO8601Date", null]
        else
          super
        end
      end

      private

      def generate_column_string(column)
        name = column.name
        required = column.null ? "" : "!"
        type = column_type_string(column)
        "#{name}:#{required}#{type}"
      end

      def column_type_string(column)
        column.name == "id" ? "ID" : column.type.to_s.camelize
      end

      def class_exists?
        klass.is_a?(Class) && klass.ancestors.include?(ActiveRecord::Base)
      rescue NameError
        return false
      end

      def klass
        @klass ||= Module.const_get(type_name.camelize)
      end
    end
  end
end
